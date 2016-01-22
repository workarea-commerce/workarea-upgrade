module Weblinc
  module Upgrade
    class Diff
      class DiffGemNotFound < StandardError; end

      attr_reader :from_files

      def full
        @common_files.map do |file|
          diff = diff_file(file)
          diff unless diff.blank?
        end.compact
      end

      def against_project
        files = file_intersection(@from_files, @project_files) + @decorated_in_project

        files.map do |file|
          diff = diff_file(file)
          diff unless diff.blank?
        end.compact
      end

      def decorated_files
        @project_decorated ||= decorated_in_project.map do |file|
          "#{file[:full_path]}\n"
        end
      end

      def overridden_files
        @project_overridden ||= file_intersection(@project_files, @from_files).map do |file|
          "#{file[:full_path]}\n"
        end
      end

      def added_files
        @base_added ||= file_difference(@to_files, @from_files).map do |file|
          "#{file[:full_path].gsub(gem_install_path, '')}\n"
        end
      end

      def removed_files
        @base_removed ||= file_difference(@from_files, @to_files).map do |file|
          "#{file[:full_path].gsub(gem_install_path, '')}\n"
        end
      end

      def initialize(from_version, to_version)
        @from_version = from_version
        @to_version = to_version

        @from_files = files_for(from_version)
        @to_files = files_for(to_version)

        @common_files = file_intersection(@from_files, @to_files)

        @project_files = filesystem_for(Rails.root.to_s)
      end

      private

      def decorated_in_project
        @decorated_in_project ||= @project_files.map do |file|
          if file[:full_path].include?('_decorator.rb')
            {
              full_path: project_to_gem_path(file[:full_path]).gsub('_decorator.rb', '.rb'),
              relative_path: file[:relative_path].gsub('_decorator.rb', '.rb')
            }
          end
        end.compact
      end

      def diff_file(file)
        from_path = file[:full_path]
        to_path = bump_gem_path(from_path, @from_version, @to_version)

        Diffy::Diff.new(
          from_path,
          to_path,
          source: 'files',
          context: 5,
          include_diff_info: true
        ).to_s
      end

      def project_to_gem_path(path)
        gem_name = /weblinc\/([a-z_]+)/.match(path)[0]
        gem_path = path.gsub(Rails.root.to_s, '')

        "#{gem_install_path}/#{gem_name.gsub('/', '-')}-#{@from_version}/#{gem_path}"
      end

      def bump_gem_path(path, from, to)
        path.gsub(/(weblinc-[a-z_]+-)#{from}/, "\\1#{to}")
      end

      def query_full_path(files, relative_path)
        files.select do |file|
          file[:relative_path] == relative_path
        end
      end

      def file_difference(from, to)
        difference = from.map{ |f| f[:relative_path] } - to.map{ |f| f[:relative_path] }
        from.select{ |f| difference.include? f[:relative_path] }
      end

      def file_intersection(from, to)
        intersection = from.map{ |f| f[:relative_path] } & to.map{ |f| f[:relative_path] }
        from.select{ |f| intersection.include? f[:relative_path] }
      end

      def files_for(version)
        files = []
        core_gem_names.each do |name|
          path = "#{gem_install_path}/#{name}-#{version}"

          gem_installed?(path)

          files += filesystem_for(path)
        end

        files
      end

      def filesystem_for(path)
        Dir.glob(File.join(path, '**', '*'))
           .select { |p| whitelisted?(p) }
           .map{ |p| { full_path: p, relative_path: p.gsub(path, '') } }
      end

      def whitelisted?(file)
        File.directory?(file) || file.include?('app') || file.include?('lib')
      end

      def gem_install_path
        begin
          path = Gem::Specification.find_by_name('weblinc').gem_dir.split('/')
        rescue NoMethodError
          raise DiffGemNotFound, "is your Gemfile pointing to a local path for the weblinc gem?"
        end

        path.first(path.size - 1).join('/')
      end

      def gem_name_from(path)
        path.split('/').last
      end

      def gem_installed?(path)
        unless File.directory?(path)
          raise DiffGemNotFound, "#{gem_name_from(path)} must be installed locally before continuing"
        end
      end

      def core_gem_names
        [
          'weblinc-store_front',
          'weblinc-core',
          'weblinc-admin'
        ]
      end
    end
  end
end
