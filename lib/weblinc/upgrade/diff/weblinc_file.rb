module Weblinc
  module Upgrade
    class Diff
      class WeblincFile
        attr_reader :relative_path

        def self.find_files(root)
          Dir.glob("#{root}/**/*")
            .map { |f| f.gsub("#{root}/", '') }
            .select do |relative|
              !File.directory?("#{root}/#{relative}") &&
                !relative.include?('decorators/') &&
                (relative.include?('app/') || relative.include?('lib/'))
            end
            .map { |relative| new(root, relative) }
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
