module Weblinc
  module Upgrade
    class Diff
      CORE_GEM_NAMES = %w(weblinc-core weblinc-store_front weblinc-admin)

      def initialize(core_to_version, options)
        @core_to_version = core_to_version
        @options = options
      end

      def plugins
        @options[:plugins].presence || {}
      end

      def gem_diffs
        @gem_diffs ||= gems.map do |gem, to_version|
          from_path = find_from_path!(gem)
          to_path = find_to_path!(gem, to_version)
          GemDiff.new(from_path, to_path, @options)
        end
      end

      %w(
        all
        for_current_app
        added
        removed
        overridden
        decorated
        customized_files
      ).each do |method|
        define_method method do
          gem_diffs.map(&method.to_sym).reduce(&:+)
        end
      end

      def gems
        core = CORE_GEM_NAMES.inject({}) do |memo, gem|
          memo[gem.gsub(/weblinc-/, '')] = @core_to_version
          memo
        end

        core.merge(plugins)
      end

      def find_from_path!(gem)
        Bundler.load.specs.find { |s| s.name == "weblinc-#{gem}" }.full_gem_path
      end

      def find_to_path!(gem, version)
        unless version.to_s =~ /^(\d+\.)(\d+\.)(\d+)$/
          raise "#{version} is not a valid version number. Example format: 2.0.3"
        end

        result = "#{Gem.dir}/gems/weblinc-#{gem}-#{version}"

        if !File.directory?(result)
          raise <<-eos.strip_heredoc

            Couldn't find weblinc-#{gem} v#{version} in installed gems!
            Looked in #{result}
            Try `gem install weblinc-#{gem} -v #{version}`.
          eos
        end

        result
      end
    end
  end
end
