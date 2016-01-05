module Weblinc
  module Upgrade
    class Migration
      class MigrationNotAvailable < StandardError; end
      class MigrationAlreadyRun < StandardError; end

      include Mongoid::Document

      field :success, type: Boolean, default: false
      field :error, type: String

      def self.lookup(version)
        "Weblinc::Upgrade::Migration::V#{version}"
          .constantize
          .new

      rescue NameError
        raise MigrationNotAvailable, "there is no migration defined for v#{version}"
      end

      def run!
        assert_not_run!
        perform
      end

      def perform
        raise NotImplementedError
      end

      private

      def assert_not_run!
        if self.class.where(success: true).exists?
          raise MigrationAlreadyRun,
            'this migration has already run successfully'
        end
      end
    end
  end
end
