# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class RepositoryBundlePipeline
        include Pipeline

        abort_on_failure!
        file_extraction_pipeline!
        relation_name BulkImports::FileTransfer::ProjectConfig::REPOSITORY_BUNDLE_RELATION

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          bundle_path = File.join(tmpdir, "#{self.class.relation}.bundle")

          BulkImports::Pipeline::ExtractedData.new(data: bundle_path)
        end

        def load(_context, bundle_path)
          Gitlab::Utils.check_path_traversal!(bundle_path)
          Gitlab::Utils.check_allowed_absolute_path!(bundle_path, [Dir.tmpdir])

          return unless File.exist?(bundle_path)
          return if File.directory?(bundle_path)
          return if File.lstat(bundle_path).symlink?

          portable.repository.create_from_bundle(bundle_path)
        end

        def after_run(_)
          FileUtils.remove_entry(tmpdir) if Dir.exist?(tmpdir)
        end

        private

        def tar_filename
          "#{self.class.relation}.tar"
        end

        def targz_filename
          "#{tar_filename}.gz"
        end

        def download_service
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(self.class.relation),
            tmpdir: tmpdir,
            filename: targz_filename
          )
        end

        def decompression_service
          BulkImports::FileDecompressionService.new(tmpdir: tmpdir, filename: targz_filename)
        end

        def extraction_service
          BulkImports::ArchiveExtractionService.new(tmpdir: tmpdir, filename: tar_filename)
        end

        def tmpdir
          @tmpdir ||= Dir.mktmpdir('bulk_imports')
        end
      end
    end
  end
end
