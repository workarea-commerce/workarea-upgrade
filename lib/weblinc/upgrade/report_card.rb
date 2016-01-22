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
        @diff.decorated_files + @diff.overridden_files
      end

      # If a file was decorated or overridden and removed, this is the
      # biggest pain point.
      def worst_files
        customized_files | @diff.removed_files
      end

      def results
        CATEGORIES.inject({}) do |memo, category|
          memo[category] = calculate_grade(category)
          memo
        end
      end

      def calculate_grade(category)
        total = customized_files.select { |f| f.include?(category) }.count
        return 'A' if total <= 2

        total_count = diff.from_files.select { |f| f.include?(category) }.count
        percent_customized = (total / total_count.to_f) * 100

        score = 0
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

        score += worst_files.select { |f| f.include?(category) }.count

        if score.between?(0, 9)
          'A'
        elsif score.between?(10, 19)
          'B'
        elsif score.between?(20, 29)
          'C'
        elsif score.between?(30, 39)
          'D'
        else
          'F'
        end
      end
    end
  end
end
