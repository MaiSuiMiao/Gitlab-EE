import { mockIssuable as issuable } from '../issuable_list/mock_data';

export const mockIssuable = {
  ...issuable,
  id: 'gid://gitlab/Issue/30',
  title: 'Sample title',
  titleHtml: 'Sample title',
  description: '# Summary',
  descriptionHtml:
    '<h1 data-sourcepos="1:1-1:25" dir="auto">&#x000A;<a id="user-content-magnoque-it-lurida-deus" class="anchor" href="#magnoque-it-lurida-deus" aria-hidden="true"></a>Summary</h1>',
  state: 'opened',
  blocked: false,
  confidential: false,
  currentUserTodos: {
    nodes: [
      {
        id: 'gid://gitlab/Todo/489',
        state: 'done',
      },
    ],
  },
};

export const mockIssuableShowProps = {
  issuable: mockIssuable,
  descriptionHelpPath: '/help/user/markdown',
  descriptionPreviewPath: '/gitlab-org/gitlab-shell/preview_markdown',
  editFormVisible: false,
  enableAutocomplete: true,
  enableEdit: true,
  statusBadgeClass: 'status-box-open',
  statusIcon: 'issue-open-m',
};
