require 'spec_helper'

module Weblinc
  module Upgrade
    describe Migration do
      describe '.lookup' do
        it 'returns an instance of the matching migration' do
          result = Migration.lookup(2)
          expect(result.class).to eq(Migration::V2)
        end

        it 'raises if no migration is defined' do
          expect { Migration.lookup(1) }
            .to raise_error(Migration::MigrationNotAvailable)
        end
      end

      describe '#run!' do
        it 'raises if there is already a successful record of the migration' do
          instance = Migration::V2.create!(success: true)

          expect { instance.run! }
            .to raise_error(Migration::MigrationAlreadyRun)
        end
      end
    end
  end
end
