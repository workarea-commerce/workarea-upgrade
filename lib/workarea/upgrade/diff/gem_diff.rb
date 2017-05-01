module Workarea
  module Upgrade
    class Diff
      class GemDiff
        def initialize(from_root, to_root, options = {})
          @from_root = from_root
          @to_root = to_root
          @options = options
        end

        def all
          @all ||= from_files.reduce([]) do |results, from_file|
            if to_file = find_to_file(from_file.relative_path)
              diff = diff_files(from_file, to_file)
              results << diff unless diff.blank?
            end

            results
          end
        end

        def added
          @added ||= to_files.reduce([]) do |results, to_file|
            from_file = find_from_file(to_file.relative_path)
            results << to_file.relative_path if from_file.blank?
            results
          end
        end

        def removed
          @removed ||= from_files.reduce([]) do |results, from_file|
            to_file = find_to_file(from_file.relative_path)
            results << from_file.relative_path if to_file.blank?
            results
          end
        end

        def overridden
          @overridden ||= find_app_diff(CurrentApp.files)
        end

        def decorated
          @decorated ||= find_app_diff(CurrentApp.decorators)
        end

        def customized_files
          CurrentApp.files.map(&:relative_path) +
            CurrentApp.decorators.map(&:relative_path)
        end

        def for_current_app
          @for_current_app ||= overridden + decorated
        end

        def from_files
          @from_files ||= WorkareaFile.find_files(@from_root)
        end

        def to_files
          @to_files ||= WorkareaFile.find_files(@to_root)
        end

        private

        def diff_files(from_file, to_file)
          Diffy::Diff.new(
            from_file.absolute_path,
            to_file.absolute_path,
            source: 'files',
            context: @options[:context].presence || 5,
            include_diff_info: true
          ).to_s(@options[:format].presence || :text)
        end

        def find_from_file(relative_path)
          relative_path = relative_path.gsub('workarea', 'weblinc') if @options[:transition]
          from_files.detect { |file| file.relative_path == relative_path }
        end

        def find_to_file(relative_path)
          relative_path = relative_path.gsub('weblinc', 'workarea') if @options[:transition]
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
end
