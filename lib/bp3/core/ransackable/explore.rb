# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/parameter_filter'

module Bp3
  module Core
    module Ransackable
      EXPLORE = :explore

      # Explore answers ransack's allowlist questions when asked with EXPLORE as the auth_object. It
      # allows the columns and the ransackers, but never an encrypted attribute, a column matching
      # filter_parameters, a column of a type that cannot be grouped or read as a value, or one the
      # model names in unexplorable_columns; and only the associations the model names in
      # explorable_associations. Ransack asks a joined model with the same auth_object, so the target
      # of an allowed association is held to the same rules.
      #
      # Ransackable includes this. A model that must not allow plain ransack includes this alone: it
      # answers nothing to any other auth_object, since defining these methods is what ransack takes
      # as an allowlist.
      module Explore
        extend ActiveSupport::Concern

        UNEXPLORABLE_TYPES = %i[json jsonb binary tsvector vector halfvec].freeze

        included do
          # Override in subclasses: the associations an explore filter may join through
          class_attribute :explorable_associations, instance_accessor: false, default: []
          # Override in subclasses: columns explore may not touch that no other rule catches
          class_attribute :unexplorable_columns, instance_accessor: false, default: []
        end

        class_methods do
          def ransackable_attributes(auth_object = nil)
            return [] unless auth_object == EXPLORE

            exceptions = Ransackable.attribute_exceptions.map(&:to_s)
            column_names.map(&:to_s) + _ransackers.keys - exceptions - unexplorable_attributes
          end

          def ransackable_associations(auth_object = nil)
            return [] unless auth_object == EXPLORE

            reflect_on_all_associations.map { |reflection| reflection.name.to_s } & explorable_associations.map(&:to_s)
          end

          def unexplorable_attributes
            filter = ActiveSupport::ParameterFilter.new(Ransackable.filter_parameters + filter_attributes)
            names = column_names.map(&:to_s)
            filtered = names.reject { |name| filter.filter(name => name)[name] == name }
            typed = columns.select { |column| UNEXPLORABLE_TYPES.include?(column.type) }.map(&:name)
            encrypted_attributes.to_a.map(&:to_s) + filtered + typed + unexplorable_columns.map(&:to_s)
          end
        end
      end
    end
  end
end
