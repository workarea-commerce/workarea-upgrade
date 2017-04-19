module Workarea
  module Upgrade
    class ReportCard
      CATEGORIES = %w(
        assets
        controllers
        helpers
        listeners
        mailers
        models
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

      private

      def customized_files_now_missing
        @diff.customized_files & @diff.removed
      end
    end
  end
end
