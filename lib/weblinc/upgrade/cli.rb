module Weblinc
  module Upgrade
    class CLI < Thor
      desc 'diff TO_VERSION', 'Output a diff for upgrading to TO_VERSION'
      option :full, type: :boolean, aliases: :f, desc: 'Output the full diff between the two weblinc verions (not just files customized in this project)'
      option :context, type: :numeric, aliases: :c, desc: 'The number of lines of context that are shown around each change'
      def diff(to)
        check_help!(to, 'diff')
        to_path = find_to_path!(to)
        diff = Diff.new(from_path, to_path, context: options[:context])

        if options[:full]
          puts diff.all.join
        else
          puts diff.for_current_app.join
        end
      end

      desc 'show_added_files TO_VERSION', 'Output a list of added files in TO_VERSION'
      def show_added_files(to)
        check_help!(to, 'show_added_files')
        to_path = find_to_path!(to)
        diff = Diff.new(from_path, to_path)
        puts diff.added.join("\n")
      end

      desc 'show_removed_files TO_VERSION', 'Output a list of removed files in TO_VERSION'
      def show_removed_files(to)
        check_help!(to, 'show_removed_files')
        to_path = find_to_path!(to)
        diff = Diff.new(from_path, to_path)
        puts diff.removed.join("\n")
      end

      desc 'report TO_VERSION', 'Output a report on upgrading to TO_VERSION'
      def report(to)
        check_help!(to, 'report')
        to_path = find_to_path!(to)
        diff = Diff.new(from_path, to_path)
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
          customized = report_card.customized_percents[category]
          total = report_card.changed_totals[category]
          say_status category, "#{customized}% of #{total} changes are customized"
        end
        puts
        report_card.results.each do |category, grade|
          say_status category, "#{report_card.worst_files[category]} customized files have been moved or removed"
        end

        puts
        puts 'Where do I go from here?'
        puts '------------------------'
        say_status 'Check out the release notes:', calculate_release_notes_url(to), :white
        say_status 'View a diff for your project:', "weblinc_upgrade diff #{to}", :white
        say_status 'View new files in weblinc:', "weblinc_upgrade show_added_files  #{to}", :white
        say_status 'View removed files in weblinc:', "weblinc_upgrade show_removed_files #{to}", :white
        say_status 'Update your gem file:', "gem 'weblinc', '#{to}'", :white
        say_status 'Migrate the database:', "rake weblinc:upgrade:migrate", :white
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

      def find_to_path!(arg)
        unless arg.to_s =~ /^(\d+\.)(\d+\.)(\d+)$/
          raise "#{arg} is not a valid version number. Example format: 2.0.3"
        end

        result = "#{Gem.dir}/gems/weblinc-#{arg}"

        if !File.directory?(result)
          raise <<-eos.strip_heredoc

            Couldn't find the desired v#{arg} in installed gems!
            Looked in #{result}
            Try `gem install weblinc -v #{arg}`.
          eos
        end

        result
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
    end
  end
end
