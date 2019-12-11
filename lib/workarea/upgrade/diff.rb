module Workarea
  module Upgrade
    class Diff
      CSS = <<-STYLE
        .diff{overflow:auto;}
        .diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
        .diff del, .diff ins{display:block;text-decoration:none;}
        .diff li{padding:0; display:table-row;margin: 0;height:1em;}
        .diff li.ins{background:#dfd; color:#080}
        .diff li.del{background:#fee; color:#b00}
        .diff li:hover{background:#ffc}
        /* try 'whitespace:pre;' if you don't want lines to wrap */
        .diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
        .diff del strong{font-weight:normal;background:#fcc;}
        .diff ins strong{font-weight:normal;background:#9f9;}
        .diff li.diff-comment { background: none repeat scroll 0 0 gray; }
        .diff li.diff-block-info { background: none repeat scroll 0 0 gray; }
      STYLE

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

          GemDiff.new(
            from_path,
            to_path,
            @options
          )
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
        %w(workarea-core workarea-storefront workarea-admin)
          .each_with_object({}) { |gem, memo| memo[gem] = @core_to_version }
          .merge(plugins)
          .select { |gem, _version| find_from_path!(gem).present? }
      end

      def find_from_path!(gem)
        Bundler.load.specs.find { |s| s.name == "#{gem}" }&.full_gem_path
      end

      def find_to_path!(gem, version)
        unless version.to_s =~ /^(\d+\.)(\d+\.)(\d+)/
          raise "#{version} is not a valid version number. Example format: 3.0.5"
        end

        result = "#{Gem.dir}/gems/#{gem}-#{version}"

        if !File.directory?(result)
          raise <<-eos.strip_heredoc

            Couldn't find #{gem} v#{version} in installed gems!
            Looked in #{result}
            Try `gem install #{gem} -v #{version}`.
          eos
        end

        result
      end
    end
  end
end
