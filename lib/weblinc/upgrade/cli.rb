module Weblinc
  module Upgrade
    class CLI < Thor
      desc 'diff TO_VERSION', 'Print a diff for upgrading to TO_VERSION'
      def diff(to)
        puts "diff #{to}"
      end

      desc 'report TO_VERSION', 'Print a report on upgrading to TO_VERSION'
      def report(to)
        puts "report #{to}"
      end
    end
  end
end
