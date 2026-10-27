# frozen_string_literal: true

RSpec.describe Bp3::Core::FeatureFlags do
  subject(:flags) { Class.new { include Bp3::Core::FeatureFlags }.new }

  # Feature::Enabler.on as the host app defines it: true or false when an enabler is set, else default
  let(:enabler) do
    Class.new do
      class << self
        attr_accessor :state

        def on(_slug, default: nil, **)
          state.nil? ? default : state
        end
      end
    end
  end

  before { stub_const('Feature::Enabler', enabler) }

  def ref_with(configs)
    Struct.new(:configs).new(configs)
  end

  describe '#efon?' do
    it 'is false when the enabler is disabled, whatever the default' do
      enabler.state = false
      expect(flags.efon?('flag', default: true)).to be(false)
    end

    it 'is true when the enabler is enabled, whatever the default' do
      enabler.state = true
      expect(flags.efon?('flag', default: false)).to be(true)
    end

    it 'is the default when no enabler is set' do
      expect([flags.efon?('flag', default: true), flags.efon?('flag')]).to eq([true, false])
    end
  end

  describe '#cfon?' do
    it 'is false when the config is false, whatever the default' do
      expect(flags.cfon?(:flag, ref: ref_with({ flag: false }), default: true)).to be(false)
    end

    it 'is true when the config is true, whatever the default' do
      expect(flags.cfon?(:flag, ref: ref_with({ flag: true }), default: false)).to be(true)
    end

    it 'is the default when the config is not set' do
      expect(flags.cfon?(:flag, ref: ref_with({}), default: true)).to be(true)
    end

    it 'is the default when there is no ref' do
      expect([flags.cfon?(:flag, default: true), flags.cfon?(:flag)]).to eq([true, false])
    end
  end
end
