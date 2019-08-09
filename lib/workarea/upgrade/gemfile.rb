module Workarea
  module Upgrade
    class Gemfile
      def initialize(filename = 'Gemfile')
        @filename = filename
      end

      def self.diff(gemfile, gemfile_next)
        gemfile_next.installed.reject do |gem|
          gemfile.installed.to_h[gem.first] != gem.second
        end
      end

      def exist?
        File.exist?(@filename)
      end

      def lockfile_exist?
        File.exist?("#{@filename}.lock")
      end

      def workarea
        installed.select { |g| g.first == 'workarea' }
      end

      def workarea_version
        workarea.first.last
      end

      def plugins(ignored = [])
        installed.reject do |gem|
          gem.first == 'workarea' || ignored.include?(gem.first)
        end
      end

      def check_install
        Bundler.with_original_env do
          system("bundle install --gemfile #{@filename} > /dev/null")
          $? == 0
        end
      end

      def install!
        Bundler.with_original_env do
          `bundle install --gemfile #{@filename}`
        end
      end

      def installed
        @installed ||=
          install!
            .split("\n")
            .select { |g| g.start_with?('Using workarea') }
            .map(&:split)
            .map { |g| [g[1], g[2]] }
            .reject { |g| core_engines.include?(g.first) }
      end

      def all_gems(ignored = [])
        installed.reject { |g| ignored.include?(g.first) }
      end

      def outdated
        @outdated ||=
          Bundler.with_original_env do
            `bundle outdated --parseable`
              .split("\n")
              .select { |g| g.start_with?('workarea') }
              .map { |g| g.gsub(/([^\s]*)\s*\(newest\s([^,]*).*/, '\\1|\\2') }
              .map { |g| g.split('|') }
              .reject { |g| core_engines.include?(g.first) }
          end
      end

      def list
        @list ||=
          Bundler.with_original_env do
            `bundle list`
              .split("\n")
              .select { |g| g.start_with?(' * workarea') }
              .map { |g| g.gsub(/[ *]+([^\s]*)\s*\(([^)]*).*/, '\\1|\\2') }
              .map { |g| g.split('|') }
              .reject { |g| core_engines.include?(g.first) }
          end
      end

      private

      def core_engines
        %w[
          admin
          ci
          core
          storefront
          testing
          api-admin
          api-storefront
        ].map { |e| "workarea-#{e}" }
      end
    end
  end
end
