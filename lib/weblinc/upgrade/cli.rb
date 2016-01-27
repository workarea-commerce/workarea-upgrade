module Weblinc
  module Upgrade
    class CLI < Thor
      desc 'diff TO_VERSION', 'Print a diff for upgrading to TO_VERSION'
      option :removed, type: :boolean, aliases: :r
      option :added, type: :boolean, aliases: :a
      option :full, type: :boolean, aliases: :f
      option :context, type: :numeric, aliases: :c
      def diff(to)
        to_path = find_to_path!(to)
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
        to_path = find_to_path!(to)
        diff = Diff.new(from_path, to_path, context: options[:context])
        report_card = Weblinc::Upgrade::ReportCard.new(diff)

        puts 'Diff Statistics'
        puts '---------------'
        say_status('>>>', "#{pluralize(diff.all.length, 'file')} changed in weblinc", :yellow)
        say_status('---', "#{pluralize(diff.removed.length, 'file')} removed from weblinc", :red)
        say_status('+++', "#{pluralize(diff.added.length, 'file')} added to weblinc", :green)
        say_status('>>>', "#{pluralize(diff.overridden.length, 'overridden file')} in this app changed", :yellow)
        say_status('>>>', "#{pluralize(diff.decorated.length, 'decorated file')} in this app changed", :yellow)

        #puts
        #puts 'Report Card'
        #puts '-----------'
        #report_card.results.each do |category, grade|
          #color = if grade.in?(%w(A B))
                    #:green
                  #elsif grade == 'F'
                    #:red
                  #else
                    #:yellow
                  #end

          #generator.say_status grade, category, color
        #end
        #puts
      end

      private

      def from_path
        Bundler.load.specs.find { |s| s.name == 'weblinc' }.full_gem_path
      end

      def find_to_path!(arg)
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

      def pluralize(*args)
        ActionController::Base.helpers.pluralize(*args)
      end
    end
  end
end
