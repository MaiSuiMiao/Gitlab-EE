package badgateway

import (
	"bytes"
	"fmt"
	"html/template"
	"io"
	"net/http"
	"strings"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// Error is a custom error for pretty Sentry 'issues'
type sentryError struct{ error }

type roundTripper struct {
	next            http.RoundTripper
	developmentMode bool
}

// NewRoundTripper creates a RoundTripper with a provided underlying next transport
func NewRoundTripper(developmentMode bool, next http.RoundTripper) http.RoundTripper {
	return &roundTripper{next: next, developmentMode: developmentMode}
}

func (t *roundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	start := time.Now()

	res, err := t.next.RoundTrip(r)
	if err == nil {
		return res, err
	}

	// httputil.ReverseProxy translates all errors from this
	// RoundTrip function into 500 errors. But the most likely error
	// is that the Rails app is not responding, in which case users
	// and administrators expect to see a 502 error. To show 502s
	// instead of 500s we catch the RoundTrip error here and inject a
	// 502 response.
	fields := log.Fields{"duration_ms": int64(time.Since(start).Seconds() * 1000)}
	log.WithRequest(r).WithFields(fields).WithError(&sentryError{fmt.Errorf("badgateway: failed to receive response: %v", err)}).Error()

	injectedResponse := &http.Response{
		StatusCode: http.StatusBadGateway,
		Status:     http.StatusText(http.StatusBadGateway),

		Request:    r,
		ProtoMajor: r.ProtoMajor,
		ProtoMinor: r.ProtoMinor,
		Proto:      r.Proto,
		Header:     make(http.Header),
		Trailer:    make(http.Header),
	}

	message := "GitLab is not responding"
	contentType := "text/plain"
	if t.developmentMode {
		message, contentType = developmentModeResponse(err)
	}

	injectedResponse.Body = io.NopCloser(strings.NewReader(message))
	injectedResponse.Header.Set("Content-Type", contentType)

	return injectedResponse, nil
}

func developmentModeResponse(err error) (body string, contentType string) {
	data := TemplateData{
		Time:          time.Now().Format("15:04:05"),
		Error:         err.Error(),
		ReloadSeconds: 5,
	}

	buf := &bytes.Buffer{}
	if err := developmentErrorTemplate.Execute(buf, data); err != nil {
		return data.Error, "text/plain"
	}

	return buf.String(), "text/html"
}

type TemplateData struct {
	Time          string
	Error         string
	ReloadSeconds int
}

var developmentErrorTemplate = template.Must(template.New("error502").Parse(`
<html>
<head>
<title>502: GitLab is not responding</title>
<script>
window.setTimeout(function() { location.reload() }, {{.ReloadSeconds}} * 1000)
</script>
</head>

<body>
<h1>502</h1>
<p>GitLab is not responding. The error was:</p>

<pre>{{.Error}}</pre>

<p>If you just started GDK it can take 60-300 seconds before GitLab has finished booting. This page will automatically reload every {{.ReloadSeconds}} seconds.</p>
<footer>Generated by gitlab-workhorse running in development mode at {{.Time}}.</footer>
</body>
</html>
`))
