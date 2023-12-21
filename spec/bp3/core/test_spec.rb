# frozen_string_literal: true

require 'bp3/core/test'

RSpec.describe Bp3::Core::Test do
  describe 'Ransackable' do
    it 'includes Ransackable' do
      expect(described_class.ancestors).to include(Bp3::Ransackable)
    end

    it 'provides ransack-related methods' do
      expect(described_class.ransackable_fields.sort).to eq(%i[id name])
    end

    describe 'config' do
      it 'supports attribute_exceptions' do
        allow(Bp3::Ransackable).to receive(:attribute_exceptions).and_return([:name])
        expect(described_class.ransackable_fields.sort).to eq(%i[id])
      end
      it 'supports association_exceptions' do
        site_double = double(:site, name: 'site') # rubocop:disable RSpec/VerifiedDoubles
        tenant_double = double(:tenant, name: 'tenant') # rubocop:disable RSpec/VerifiedDoubles
        allow(described_class).to receive(:reflect_on_all_associations).and_return([site_double, tenant_double])
        allow(Bp3::Ransackable).to receive(:association_exceptions).and_return([:site])
        expect(described_class.ransackable_associations.sort).to eq(%w[tenant])
      end
    end
  end
end
