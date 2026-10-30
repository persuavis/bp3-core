# frozen_string_literal: true

require 'spec_helper'

# Plain Ruby stand-ins for the part of an ActiveRecord model that Ransackable reads: this gem does not
# depend on ActiveRecord.
module RansackableStandIn
  Column = Struct.new(:name, :type)
  Reflection = Struct.new(:name)

  def self.included(base)
    base.extend(ClassMethods)
  end

  # What an ActiveRecord class answers
  module ClassMethods
    def columns
      [Column.new('id', :uuid), Column.new('name', :string), Column.new('token_hash', :string),
       Column.new('email', :string), Column.new('details', :jsonb), Column.new('raw', :binary),
       Column.new('tsv', :tsvector), Column.new('embedding', :halfvec), Column.new('authentication', :string)]
    end

    def column_names
      columns.map(&:name)
    end

    def reflect_on_all_associations
      [Reflection.new(:site), Reflection.new(:tenant)]
    end

    def _ransackers
      { 'hour_of_day' => Object.new }
    end

    def filter_attributes
      [:token_hash]
    end

    def encrypted_attributes
      Set[:email]
    end
  end
end

class RansackableModel
  include RansackableStandIn
  include Bp3::Core::Ransackable
end

class ExploreOnlyModel
  include RansackableStandIn
  include Bp3::Core::Ransackable::Explore
end

class ExplorableAssociationModel < RansackableModel
  self.explorable_associations = %w[site]
  self.unexplorable_columns = %w[authentication]
end

RSpec.describe Bp3::Core::Ransackable do
  let(:explore) { described_class::EXPLORE }

  describe 'a model with Ransackable' do
    it 'allows every column and association to plain ransack' do
      expect([RansackableModel.ransackable_attributes.size, RansackableModel.ransackable_associations])
        .to eq([9, %w[site tenant]])
    end

    it 'gives any other auth_object the plain answer' do
      expect(RansackableModel.ransackable_attributes(Object.new)).to include('email', 'details')
    end

    it 'allows only what explore may touch, and its ransackers' do
      expect(RansackableModel.ransackable_attributes(explore))
        .to contain_exactly('id', 'name', 'authentication', 'hour_of_day')
    end

    it 'never allows a column matching filter_parameters to explore' do
      allow(described_class).to receive(:filter_parameters).and_return([/\Aname\z/])
      expect(RansackableModel.ransackable_attributes(explore)).not_to include('name')
    end

    it 'never allows an attribute exception to explore' do
      allow(described_class).to receive(:attribute_exceptions).and_return(%w[name])
      expect(RansackableModel.ransackable_attributes(explore)).not_to include('name')
    end

    it 'allows no association to explore unless the model names it' do
      expect(RansackableModel.ransackable_associations(explore)).to be_empty
    end

    it 'has no filter parameters outside Rails' do
      expect(described_class.filter_parameters).to eq([])
    end
  end

  describe 'a model that names what explore may touch' do
    it 'allows the associations it names' do
      expect(ExplorableAssociationModel.ransackable_associations(explore)).to eq(%w[site])
    end

    it 'refuses the columns it names' do
      expect(ExplorableAssociationModel.ransackable_attributes(explore)).not_to include('authentication')
    end

    it 'does not change the model it inherits from' do
      expect(RansackableModel.unexplorable_columns).to eq([])
    end
  end

  describe 'a model with Explore alone' do
    it 'answers explore as Ransackable does' do
      expect(ExploreOnlyModel.ransackable_attributes(explore)).to eq(RansackableModel.ransackable_attributes(explore))
    end

    it 'allows nothing to plain ransack' do
      expect([ExploreOnlyModel.ransackable_attributes, ExploreOnlyModel.ransackable_associations]).to eq([[], []])
    end
  end
end
