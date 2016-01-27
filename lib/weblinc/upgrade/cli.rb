module Weblinc
  module Upgrade
    class CLI < Thor
      desc 'diff TO_VERSION', 'Print a diff for upgrading to TO_VERSION'
      option :removed, type: :boolean, aliases: :r
      option :added, type: :boolean, aliases: :a
      option :full, type: :boolean, aliases: :f
      option :context, type: :numeric, aliases: :c
      def diff(to)
        from_path = Bundler.load.specs.find { |s| s.name == 'weblinc' }.full_gem_path
        to_path = "#{Gem.dir}/gems/weblinc-#{to}"
        # TODO ensure that path exists

        diff = Diff.new(from_path, to_path, context: options[:context])

        if options[:removed]
          puts diff.removed.join("\n")
        elsif options[:added]
          puts diff.added.join("\n")
        elsif options[:full]
          puts diff.all.join
        else
          puts diff.for_current_app.join
        end
      end

      desc 'report TO_VERSION', 'Print a report on upgrading to TO_VERSION'
      def report(to)
        puts "report #{to}"
      end
    end
  end
end
