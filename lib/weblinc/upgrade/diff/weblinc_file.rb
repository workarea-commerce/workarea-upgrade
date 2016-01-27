module Weblinc
  module Upgrade
    class Diff
      class WeblincFile
        CORE_GEM_NAMES = %w(weblinc-core weblinc-store_front weblinc-admin)

        attr_reader :relative_path

        def self.find_from_gems(gems_root, version)
          files = []

          CORE_GEM_NAMES.each do |name|
            gem_root = "#{gems_root}/#{name}-#{version}"
            results = find_files(gem_root)

            files += results.map do |file|
              WeblincFile.new(gem_root, file.gsub("#{gem_root}/", ''))
            end
          end

          files
        end

        def self.find_files(root)
          Dir.glob("#{root}/**/*").select do |file|
            relative = file.gsub(root, '')

            !File.directory?(file) &&
              !relative.include?('decorators/') &&
              (relative.include?('app/') || relative.include?('lib/'))
          end
        end

        def self.find_decorators(root)
          Dir.glob("#{root}/app/decorators/**/*")
            .reject { |file| File.directory?(file) }
            .map { |file| file.gsub(root, '') }
            .map { |file| file.gsub('/app/decorators', 'app') }
            .map { |file| file.gsub('_decorator.rb', '.rb') }
            .map { |file| new(nil, file) }
        end

        def initialize(root, relative_path)
          @root = root
          @relative_path = relative_path
        end

        def absolute_path
          "#{@root}/#{@relative_path}"
        end
      end
    end
  end
end
