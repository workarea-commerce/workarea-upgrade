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
            @options.merge(transition: transitioning_to_workarea?)
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
        core = core_gem_names.inject({}) do |memo, gem|
          memo[gem.split('-').last] = @core_to_version
          memo
        end

        core.merge(plugins)
      end

      def find_from_path!(gem)
        gem = 'store_front' if gem == 'storefront' && transitioning_to_workarea?
        Bundler.load.specs.find { |s| s.name == "#{from_name}-#{gem}" }.full_gem_path
      end

      def find_to_path!(gem, version)
        unless version.to_s =~ /^(\d+\.)(\d+\.)(\d+)$/
          raise "#{version} is not a valid version number. Example format: 3.0.5"
        end

        result = "#{Gem.dir}/gems/#{to_name}-#{gem}-#{version}"

        if !File.directory?(result)
          raise <<-eos.strip_heredoc

            Couldn't find #{to_name}-#{gem} v#{version} in installed gems!
            Looked in #{result}
            Try `gem install #{to_name}-#{gem} -v #{version}`.
          eos
        end

        result
      end

      def core_gem_names
        @core_gem_names ||=
          if workarea_upgrade?
            %w(workarea-core workarea-storefront workarea-admin)
          else
            %w(weblinc-core weblinc-store_front weblinc-admin)
          end
      end

      def from_name
        @from_name ||=
          if weblinc_upgrade? || transitioning_to_workarea?
            'weblinc'
          else
            'workarea'
          end
      end

      def to_name
        @to_name ||= workarea_upgrade? ? 'workarea' : 'weblinc'
      end

      def weblinc_upgrade?
        @weblinc_upgrade ||= @core_to_version.to_s.split('.').first.to_i < 3
      end

      def workarea_upgrade?
        @workarea_upgrade ||= @core_to_version.to_s.split('.').first.to_i >= 3
      end

      # If the version is 3+ and a weblinc gem is still found, we can reliably say
      # this is a diff between v2 and v3.
      def transitioning_to_workarea?
        @transitioning_to_workarea ||=
          workarea_upgrade? &&
          Bundler.load.specs.any? { |s| s.name =~ /^weblinc/ }
      end
    end
  end
end
