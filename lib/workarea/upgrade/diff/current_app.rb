module Workarea
  module Upgrade
    class Diff
      module CurrentApp
        def self.files
          @files ||= WorkareaFile.find_files(Dir.pwd)
        end

        def self.decorators
          @decorators ||= WorkareaFile.find_decorators(Dir.pwd)
        end
      end
    end
  end
end
