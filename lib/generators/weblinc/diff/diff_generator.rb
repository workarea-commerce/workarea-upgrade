module Weblinc
  module Generators
    class DiffGenerator < Rails::Generators::Base
      require 'weblinc/upgrade/diff'

      desc File.read(File.expand_path('../USAGE', __FILE__))

      argument :from_version, type: :string, required: true
      argument :to_version, type: :string, required: true

      def diff
        diff = Weblinc::Upgrade::Diff.new(from_version, to_version)

        determine_export_path

        print_status('---', 'removed', 'red', diff.removed_files)
        export(diff.removed_files, 'removed', 'txt')

        print_status('+++', 'added', 'green', diff.added_files)
        export(diff.added_files, 'added', 'txt')

        print_status('>>>', 'overridden', 'yellow', diff.overridden_files)
        export(diff.overridden_files, 'overridden', 'txt')

        print_status('>>>', 'decorated', 'yellow', diff.decorated_files)
        export(diff.decorated_files, 'decorated', 'txt')

        export(diff.full, 'full diff', 'diff')
        export(diff.against_project, 'project-specific', 'diff')
      end

      def print_status(indicator, type, color, files)
        say_status indicator, "#{files.count} have been #{type} from weblinc", color.to_sym
      end

      private

      def determine_export_path
        @export_path = "#{Rails.root}/tmp/upgrade_diffs/v#{from_version}_v#{to_version}"

        dialog = ask "Output diff info to #{@export_path}? (Y/n)"
        unless dialog =~ /y/i || dialog.blank?
          @export_path = ask "In what directory would you like to save the diff info?"
        end

        @export_path = File.expand_path(@export_path)

        unless File.directory?(@export_path)
          say_status 'create', "Creating #{@export_path}...", :white
          FileUtils::mkdir_p @export_path

          puts
        end
      end

      def export(files, type, ext)
        if files.count > 0
          path = "#{@export_path}/#{type.gsub(/[-\s]/, '_')}.#{ext}"

          say_status 'export', "#{type} to #{path}", :white
          File.write(path, files.join)
        end
      end
    end
  end
end
