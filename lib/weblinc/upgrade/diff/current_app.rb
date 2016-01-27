module Weblinc
  module Upgrade
    class Diff
      module CurrentApp
        def self.files
          @current ||= WeblincFile.find_files(Dir.pwd).map do |file|
            WeblincFile.new(Dir.pwd, file.gsub("#{Dir.pwd}/", ''))
          end
        end

        def self.decorators
          @decorators ||= WeblincFile.find_decorators(Dir.pwd)
        end
      end
    end
  end
end
