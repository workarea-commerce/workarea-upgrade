module Weblinc
  module Upgrade
    class Diff
      module CurrentApp
        def self.files
          @files ||= WeblincFile.find_files(Dir.pwd)
        end

        def self.decorators
          @decorators ||= WeblincFile.find_decorators(Dir.pwd)
        end
      end
    end
  end
end
