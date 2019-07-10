module Workarea
  module Upgrade
    class Report
      CATEGORIES = %w(
        assets
        controllers
        helpers
        mailers
        middleware
        models
        queries
        seeds
        services
        view_models
        views
        workers
      )

      def initialize(diff)
        @diff = diff
      end

      def results
        CATEGORIES.inject({}) do |memo, category|
          memo[category] = calculate_grade(category)
          memo
        end
      end

      def customized_percents
        @customized_percents ||= CATEGORIES.inject({}) do |memo, category|
          percent_customized = customized_totals[category] / changed_totals[category].to_f
          percent_customized *= 100

          memo[category] = percent_customized.nan? ? 0 : percent_customized.round
          memo
        end
      end

      # If a file was decorated or overridden and removed, this is the
      # biggest pain point.
      def worst_files
        @worst_files ||= CATEGORIES.inject({}) do |memo, category|
          memo[category] = customized_files_now_missing
                             .select { |f| f.include?(category) }
                             .count

          memo
        end
      end

      def changed_totals
        @changed_totals ||= CATEGORIES.inject({}) do |memo, category|
          memo[category] = @diff.all.select { |f| f.include?(category) }.count
          memo
        end
      end

      def customized_totals
        @customized_totals ||= CATEGORIES.inject({}) do |memo, category|
          memo[category] = @diff.for_current_app.select { |f| f.include?(category) }.count
          memo
        end
      end

      def calculate_grade(category)
        customized_total = customized_totals[category]
        return 'A' if customized_total <= 3

        percent_customized = customized_percents[category]
        return 'A' if percent_customized < 5

        score = worst_files[category]
        score += percent_customized

        if score.between?(0, 9)
          'A'
        elsif score.between?(10, 24)
          'B'
        elsif score.between?(25, 34)
          'C'
        elsif score.between?(35, 44)
          'D'
        else
          'F'
        end
      end

      def diff_stats
        [
          {
            status: ">>> #{pluralize(@diff.all.length, 'file')}",
            message: 'modified in Workarea',
            color: :yellow
          },
          {
            status: ">>> #{pluralize(@diff.overridden.length, 'file')}",
            message: 'overridden in your application may be be affected',
            color: :yellow
          },
          {
            status: ">>> #{pluralize(@diff.decorated.length, 'file')}",
            message: 'decorated in your application may be be affected',
            color: :yellow
          },
          {
            status: "+++ #{pluralize(@diff.added.length, "file")}",
            message: 'added to Workarea',
            color: :green
          },
          {
            status: "--- #{pluralize(@diff.removed.length, 'file')}",
            message: 'removed from Workarea',
            color: :red
          }
        ]
      end

      def report_card_stats
        results.map do |category, grade|
          color = :yellow
          color = :green if grade.in?(%w(A B))
          color = :red if grade == 'F'

          {
            status: "Grade: #{grade}",
            message: category,
            color: color
          }
        end
      end

      def breakdown_customized_stats
        results
          .reject { |category, _grade| customized_totals[category] == 0 }
          .map do |category, _grade|
            {
              status: category,
              message: <<~MESSAGE.gsub(/\n/, ' '),
                #{pluralize(customized_totals[category], 'file')}
                (#{customized_percents[category]}%) overridden or decorated
                in this application have been changed in Workarea
              MESSAGE
              color: :yellow
            }
          end
      end

      def breakdown_worst_files_stats
        results
          .reject { |category, _grade| worst_files[category] == 0 }
          .map do |category, _grade|
            {
              status: category,
              message: <<~MESSAGE.gsub(/\n/, ' '),
                #{pluralize(worst_files[category], 'file')} overridden or
                decorated in this application have been moved or removed from
                Workarea
              MESSAGE
              color: :red
            }
          end
      end

      private

      def customized_files_now_missing
        @diff.customized_files & @diff.removed
      end

      def pluralize(*args)
        ActionController::Base.helpers.pluralize(*args)
      end
    end
  end
end
