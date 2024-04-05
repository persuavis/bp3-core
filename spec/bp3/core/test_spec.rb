# frozen_string_literal: true

require 'bp3/core/test'

RSpec.describe Bp3::Core::Test do
  describe 'Ransackable' do
    it 'includes Ransackable' do
      expect(described_class.ancestors).to include(Bp3::Core::Ransackable)
    end

    it 'provides ransack-related methods' do
      expect(described_class.ransackable_fields.sort).to eq(%i[id name])
    end

    describe 'config' do
      it 'supports attribute_exceptions' do
        allow(Bp3::Core::Ransackable).to receive(:attribute_exceptions).and_return([:name])
        expect(described_class.ransackable_fields.sort).to eq(%i[id])
      end

      it 'supports association_exceptions' do
        site_double = double(:site, name: 'site') # rubocop:disable RSpec/VerifiedDoubles
        tenant_double = double(:tenant, name: 'tenant') # rubocop:disable RSpec/VerifiedDoubles
        allow(described_class).to receive(:reflect_on_all_associations).and_return([site_double, tenant_double])
        allow(Bp3::Core::Ransackable).to receive(:association_exceptions).and_return([:site])
        expect(described_class.ransackable_associations.sort).to eq(%w[tenant])
      end
    end
  end

  describe 'Cookies' do
    it 'includes Cookies' do
      expect(described_class.ancestors).to include(Bp3::Core::Cookies)
    end
  end

  describe 'Displayable' do
    it 'includes Displayable' do
      expect(described_class.ancestors).to include(Bp3::Core::Displayable)
    end

    it 'provides an i18n key' do
      # byebug
      expect(described_class.i18n_key).to eq('bp3/core/test')
    end
  end

  describe 'FeatureFlags' do
    it 'includes FeatureFlags' do
      expect(described_class.ancestors).to include(Bp3::Core::FeatureFlags)
    end
  end

  describe 'Rqid' do
    it 'includes Rqid' do
      expect(described_class.ancestors).to include(Bp3::Core::Rqid)
    end
  end

  describe 'Sqnr' do
    it 'includes Sqnr' do
      expect(described_class.ancestors).to include(Bp3::Core::Sqnr)
    end
  end

  describe 'Tenantable' do
    it 'includes Tenantable' do
      expect(described_class.ancestors).to include(Bp3::Core::Tenantable)
    end
  end
end
