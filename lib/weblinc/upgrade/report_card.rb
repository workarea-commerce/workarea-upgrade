module Weblinc
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

      def customized_files
        @diff.decorated + @diff.overridden_files
      end

      def results
        CATEGORIES.inject({}) do |memo, category|
          memo[category] = calculate_grade(category)
          memo
        end
      end

      def customized_percents
        @customized_percents ||= CATEGORIES.inject({}) do |memo, category|
          total = @diff.for_current_app.select { |f| f.include?(category) }.count
          total_count = @diff.all.select { |f| f.include?(category) }.count
          percent_customized = (total / total_count.to_f) * 100

          memo[category] = percent_customized.round
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


      def calculate_grade(category)
        percent_customized = customized_percents[category]
        return 'A' if percent_customized < 5

        score = worst_files[category]
        score += if percent_customized.between?(0, 10)
                   1
                 elsif percent_customized.between?(11, 25)
                   5
                 elsif percent_customized.between?(26, 50)
                   10
                 elsif percent_customized.between?(51, 74)
                   20
                 else
                   30
                 end

        if score.between?(0, 9)
          'A'
        elsif score.between?(10, 24)
          'B'
        elsif score.between?(25, 34)
          'C'
        elsif score.between?(35, 50)
          'D'
        else
          'F'
        end
      end

      private

      def customized_files_now_missing
        @diff.for_current_app | @diff.removed
      end
    end
  end
end
