module Workarea
  module Upgrade
    class CLI < Thor
      include Thor::Actions

      def self.source_root
        Dir.pwd
      end

      default_task :prepare

      desc 'prepare', 'Create a Gemfile.next'
      long_desc <<~LONG_DESC
        This plugin uses a special file, that must be present in your
        application's root directory, called Gemfile.next. This file is like
        a regular Gemfile but it contains a list of only the Workarea gems you
        wish to upgrade your application to.

        You can craft an artisanal Gemfile.next file yourself or use this
        command to walk you through the creation process. If you choose to
        handcraft your own bespoke Gemfile.next you can immediately use any of
        the other commands offered, such as "report" or "diff".

        If you want to walk through each of the versions available to you and
        customize which to include you can use this "prepare" command to
        generate or regenerate a Gemfile.next file.
      LONG_DESC
      option :latest,
        aliases: :l, type: :boolean,
        desc: 'Just use the latest Workarea gems for the upgrade'
      def prepare
        if gemfile_next.exist?
          say "\nGemfile.next already exists in #{Dir.pwd}.", :green

          if ask("\nWould you like to regenerate the file? [Yn]").casecmp?('n')
            say "\nLooks like you're ready to upgrade!", :green
            say 'Try running another command, like "diff" or "report":'
            puts
            invoke :help, [], {}
            exit(0)
          else
            remove_file 'Gemfile.next'
            remove_file 'Gemfile.next.lock'
            invoke :prepare, [], {}
          end
        elsif gemfile_next.lockfile_exist?
          remove_file 'Gemfile.next.lock'
        end

        say "\nPlease be patient; we're hacking The Gibson...", :yellow

        unless gemfile.outdated.any?
          say "\nYour application is already up to date!", :green
          exit(0)
        end

        say "\nAvailable updates:", :yellow
        gemfile.outdated.each { |g| say(" * #{g.first} (#{g.last})") }

        chosen_gems = options[:latest] ? gemfile.outdated : choose_gems

        copy_file 'Gemfile', 'Gemfile.next'

        chosen_gems.each do |gem|
          current_version = gemfile.installed.to_h[gem.first]
          gsub_file 'Gemfile.next',
            /#{gem.first}(['"].*)#{current_version}/,
            "#{gem.first}\\1#{gem.last}"
        end

        if gemfile_next.check_install
          invoke :report, [], {}
        else
          say "\nOh noes! Your Gemfile.next failed to install!", :red

          puts
          say <<~MESSAGE
            This usually happens when you try to upgrade your project to a new
            minor version. Workarea may be depending on different versions of
            gems than you currently have listed in your Gemfile.

            All this means is that we'll need a bit of human intervention for
            this next part.

            What you should do is manually edit the Gemfile.next that we've just
            created in your project. After you've made some edits you can test
            the Gemfile.next by running:

            $ bundle install --gemfile Gemfile.next

            Once you've resolved the dependency issues in your Gemfile.next you
            can pick up where you left off by running:

            $ bundle exec workarea_upgrade report
          MESSAGE

          say "\nGood luck!", :green
        end
      end

      desc 'report', 'Display an overview of the complexity of the upgrade'
      def report
        prepared?

        gems_to_ignore = Gemfile.diff(gemfile, gemfile_next).to_h.keys

        diff = Diff.new(
          gemfile_next.workarea_version,
          options.merge(plugins: gemfile_next.plugins(gems_to_ignore).to_h)
        )

        report = Report.new(diff)

        puts
        puts '###############'
        say  'Diff Statistics', :green
        puts '###############'

        display_report(report.diff_stats)

        puts
        puts '###############'
        say  '  Report Card', :green
        puts '###############'

        display_report(report.report_card_stats)

        puts
        puts '###############'
        say  '   Breakdown', :green
        puts '###############'

        display_report(report.breakdown_customized_stats)
        display_report(report.breakdown_worst_files_stats)

        puts
        puts '###############'
        say  '  Next  Steps', :green
        puts '###############'

        puts
        puts "* View a full diff of all files that will be impacted by this upgrade:"
        puts "  $ bundle exec workarea_upgrade diff"

        puts
        puts "* Replace your Gemfile and Gemfile.lock with the new versions:"
        puts "  $ mv Gemfile.next Gemfile"
        puts "  $ mv Gemfile.next.lock Gemfile.lock"

        puts
        puts "* Compare release notes between your version and #{gemfile_next.workarea_version}:"
        puts "  https://developer.workarea.com/release-notes.html"

        puts
        puts "* If you're upgrading to a new minor be sure to read the appropriate Upgrade Guide:"
        puts "  https://developer.workarea.com/upgrade-guides.html"
      end

      desc 'diff', 'Output a diff of changes that will affect your project'
      long_desc <<~LONG_DESC
        The default diff displayed will be based on changes made to the Workarea
        platform that will have an impact on the overridden or decorated files
        found in your project.

        It's purpose is to allow you to see what has changed in the underlying
        platform and to make decisions based on whether or not a given change
        should be incorporated into your app.

        To see a full log of change between versions, not just the changes that
        may or may not be relevant to your specific application, pass the
        `--full` option to this command.
      LONG_DESC
      option :format,
        aliases: :f,
        type: :string,
        default: 'color',
        enum: %w[color html]
      option :context,
        alias: :c,
        type: :numeric,
        desc: 'The number of lines displayed around each change in the diff'
      option :full,
        type: :boolean,
        desc: 'Display every change to Workarea, not just the impactful ones'
      option :added,
        type: :boolean,
        desc: 'View a list of files that were added to Workarea'
      option :removed,
        type: :boolean,
        desc: 'View a list of files that were removed from Workarea'
      def diff
        prepared?

        gems_to_ignore = Gemfile.diff(gemfile, gemfile_next).to_h.keys

        diff = Diff.new(
          gemfile_next.workarea_version,
          options.merge(plugins: gemfile_next.plugins(gems_to_ignore).to_h)
        )

        if options[:added]
          puts diff.added.join("\n")
          exit(0)
        end

        if options[:removed]
          puts diff.removed.join("\n")
          exit(0)
        end

        if options[:full]
          handle_diff_output(diff.all.join, options[:format])
        else
          handle_diff_output(diff.for_current_app.join, options[:format])
        end
      end

      private

      def gemfile
        @gemfile ||= Gemfile.new
      end

      def gemfile_next
        @gemfile_next ||= Gemfile.new('Gemfile.next')
      end

      def prepared?
        unless gemfile_next.exist?
          say "\nGemfile.next was not found in #{Dir.pwd}", :red
          say 'Preparing your application for upgrade...'
          invoke :prepare, [], {}
        end
      end

      def choose_gems
        done = 'n'

        while done.casecmp?('n')
          say "\nYou can [C]ontinue, [s]kip, or enter a new version number:"

          gems = gemfile.outdated.each_with_object([]) do |gem, memo|
            choice = ask(" * #{gem.first} (#{gem.last})", :yellow)

            next if choice.casecmp?('s')

            if choice.casecmp?('c') || choice.empty?
              memo << gem
            else
              memo << [gem.first, choice]
            end
          end

          if gems.nil?
            say('You must choose at least one gem to upgrade.', :red)
          else
            say("\nHere's what you chose:")
            gems.each { |gem| say(" * #{gem.first} (#{gem.last})", :green) }

            done = ask("\nWrite these gems to the Gemfile.next? [Ynq]")
            exit(0) if done.casecmp?('q')
          end
        end

        gems
      end

      def handle_diff_output(result, format)
        if format.to_s == 'html'
          puts <<-eos
            <!doctype html>
            <html>
              <head><style>#{Diff::CSS}</style></head>
              <body>#{result}</body>
            </html>
          eos
        else
          puts result
        end
      end

      def display_report(stats)
        stats.each do |stat|
          say_status stat[:status], stat[:message], stat[:color]
        end
      end
    end
  end
end
