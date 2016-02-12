module Weblinc
  module Upgrade
    class CLI < Thor
      desc 'diff TO_VERSION', 'Output a diff for upgrading to TO_VERSION'
      option :plugins, type: :hash, aliases: :p, desc: 'Plugins and their upgrade versions to include, e.g. reviews:1.0.1 blog:1.0.0'
      option :full, type: :boolean, aliases: :f, desc: 'Output the full diff between the two weblinc verions (not just files customized in this project)'
      option :context, type: :numeric, aliases: :c, desc: 'The number of lines of context that are shown around each change'
      option :format, type: :string, enum: %w(text color html), default: 'color'
      def diff(to)
        check_help!(to, 'diff')
        diff = Diff.new(to, options)

        if options[:full]
          handle_diff_output(diff.all.join, options[:format])
        else
          handle_diff_output(diff.for_current_app.join, options[:format])
        end
      end

      desc 'show_added_files TO_VERSION', 'Output a list of added files in TO_VERSION'
      option :plugins, type: :hash, aliases: :p, desc: 'Plugins and their upgrade versions to include, e.g. reviews:1.0.1 blog:1.0.0'
      def show_added_files(to)
        check_help!(to, 'show_added_files')
        diff = Diff.new(to, options)
        puts diff.added.join("\n")
      end

      desc 'show_removed_files TO_VERSION', 'Output a list of removed files in TO_VERSION'
      option :plugins, type: :hash, aliases: :p, desc: 'Plugins and their upgrade versions to include, e.g. reviews:1.0.1 blog:1.0.0'
      def show_removed_files(to)
        check_help!(to, 'show_removed_files')
        diff = Diff.new(to, options)
        puts diff.removed.join("\n")
      end

      desc 'report TO_VERSION', 'Output a report on upgrading to TO_VERSION'
      option :plugins, type: :hash, aliases: :p, desc: 'Plugins and their upgrade versions to include, e.g. reviews:1.0.1 blog:1.0.0'
      def report(to)
        check_help!(to, 'report')
        diff = Diff.new(to, options)
        report_card = Weblinc::Upgrade::ReportCard.new(diff)

        puts 'Diff Statistics'
        puts '---------------'
        say_status '>>>', "#{pluralize(diff.all.length, 'file')} changed in weblinc", :yellow
        say_status '---', "#{pluralize(diff.removed.length, 'file')} removed from weblinc", :red
        say_status '+++', "#{pluralize(diff.added.length, 'file')} added to weblinc", :green
        say_status '>>>', "#{pluralize(diff.overridden.length, 'overridden file')} in this app changed", :yellow
        say_status '>>>', "#{pluralize(diff.decorated.length, 'decorated file')} in this app changed", :yellow

        puts
        puts 'Report Card'
        puts '-----------'
        report_card.results.each do |category, grade|
          color = if grade.in?(%w(A B))
                    :green
                  elsif grade == 'F'
                    :red
                  else
                    :yellow
                  end

          say_status grade, category, color
        end

        puts 'Why?'
        puts '----'
        report_card.results.each do |category, grade|
          say_status category, "#{report_card.customized_totals[category]} overridden/decorated files have been changed"
        end
        puts
        report_card.results.each do |category, grade|
          say_status category, "#{report_card.customized_percents[category]}% of overridden/decorated files have been changed"
        end
        puts
        report_card.results.each do |category, grade|
          say_status category, "#{report_card.worst_files[category]} overridden/decorated files have been moved or removed"
        end

        puts
        puts 'Where do I go from here?'
        puts '------------------------'
        say_status 'Check out the release notes:', calculate_release_notes_url(to), :white
        say_status 'View a diff for your project:', "weblinc_upgrade diff #{to}", :white
        say_status 'View new files in weblinc:', "weblinc_upgrade show_added_files  #{to}", :white
        say_status 'View removed files in weblinc:', "weblinc_upgrade show_removed_files #{to}", :white
        say_status 'Update your gem file:', "gem 'weblinc', '#{to}'", :white
        puts
      end

      private

      def calculate_release_notes_url(version)
        version_pieces = version.split('.').map(&:to_i)
        major = version_pieces.first

        if major < 2
          minor = version_pieces.second
          "http://guides.weblinc.com/#{major}.#{minor}/release-notes.html"
        else
          "http://guides.weblinc.com/#{major}/release-notes.html"
        end
      end

      def from_path
        Bundler.load.specs.find { |s| s.name == 'weblinc' }.full_gem_path
      end

      def check_help!(arg, subcommand)
        if arg.to_s.strip =~ /help/i
          invoke 'help', [subcommand]
          exit
        end
      end

      def pluralize(*args)
        ActionController::Base.helpers.pluralize(*args)
      end

      def handle_diff_output(result, format)
        if format.to_s == 'html'
          puts <<-eos
            <html>
              <head><style>#{Diff::CSS}</style></head>
              <body>#{result}</body>
            </html>
          eos
        else
          puts result
        end
      end
    end
  end
end
