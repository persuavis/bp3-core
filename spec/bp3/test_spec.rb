# frozen_string_literal: true

require 'bp3/test'

RSpec.describe Bp3::Test do
  it 'includes Ransackable' do
    expect(Bp3::Test.ancestors).to include(Bp3::Ransackable)
  end

  it "provides ransack-related methods" do
    expect(described_class.ransackable_fields.sort).to eq(%i[id name])
  end
end
