module Weblinc
  module Upgrade
    class Diff
      def initialize(from_path, to_path, options = {})
        @from_root = from_path.split('/')[0..-2].join('/')
        @to_root = to_path.split('/')[0..-2].join('/')

        @from_version = from_path.split('-').last
        @to_version = to_path.split('-').last

        @options = options
      end

      def all
        from_files.reduce([]) do |results, from_file|
          if to_file = find_to_file(from_file.relative_path)
            diff = diff_files(from_file, to_file)
            results << diff unless diff.blank?
          end

          results
        end
      end

      def added
        to_files.reduce([]) do |results, to_file|
          from_file = find_from_file(to_file.relative_path)
          results << to_file.relative_path if from_file.blank?
          results
        end
      end

      def removed
        from_files.reduce([]) do |results, from_file|
          to_file = find_to_file(from_file.relative_path)
          results << from_file.relative_path if to_file.blank?
          results
        end
      end

      def overridden
        find_app_diff(CurrentApp.files)
      end

      def decorated
        find_app_diff(CurrentApp.decorators)
      end

      def for_current_app
        overridden + decorated
      end

      private

      def from_files
        @from_files ||= WeblincFile.find_from_gems(@from_root, @from_version)
      end

      def to_files
        @to_files ||= WeblincFile.find_from_gems(@to_root, @to_version)
      end

      def diff_files(from_file, to_file)
        Diffy::Diff.new(
          from_file.absolute_path,
          to_file.absolute_path,
          source: 'files',
          context: @options[:context].presence || 5,
          include_diff_info: true
        ).to_s
      end

      def find_from_file(relative_path)
        from_files.detect { |file| file.relative_path == relative_path }
      end

      def find_to_file(relative_path)
        to_files.detect { |file| file.relative_path == relative_path }
      end

      def find_app_diff(files)
        files.reduce([]) do |results, decorated_file|
          from_file = find_from_file(decorated_file.relative_path)
          to_file = find_to_file(decorated_file.relative_path)

          if from_file.present? && to_file.present?
            diff = diff_files(from_file, to_file)
            results << diff unless diff.blank?
          end

          results
        end
      end
    end
  end
end
