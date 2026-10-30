# frozen_string_literal: true

require_relative 'ransackable/explore'

module Bp3
  # Bp3::Ransackable provides class methods expected by models that use ransack. It allows every column
  # and association, except when asked with EXPLORE as the auth_object: Explore answers that.
  module Core
    module Ransackable
      extend ActiveSupport::Concern

      include Explore

      mattr_accessor :attribute_exceptions, default: []
      mattr_accessor :association_exceptions, default: []

      def self.filter_parameters
        defined?(Rails) ? Rails.application.config.filter_parameters : []
      end

      class_methods do
        def ransackable_fields(auth_object = nil)
          fields =
            ransackable_attributes(auth_object) +
            ransackable_associations(auth_object) +
            ransackable_scopes(auth_object)
          fields.map(&:to_sym).uniq
        end

        def ransackable_attributes(auth_object = nil)
          return super if auth_object == EXPLORE

          except = attribute_exceptions.map(&:to_s)
          column_names.map(&:to_s) - except
        end

        def ransackable_associations(auth_object = nil)
          return super if auth_object == EXPLORE

          except = association_exceptions.map(&:to_s)
          reflect_on_all_associations.map(&:name).map(&:to_s) - except
        end

        def ransackable_scopes(_auth_object = nil)
          []
        end

        def ransortable_attributes(auth_object = nil)
          ransackable_attributes(auth_object)
        end

        private

        def attribute_exceptions
          Bp3::Core::Ransackable.attribute_exceptions
        end

        def association_exceptions
          Bp3::Core::Ransackable.association_exceptions
        end
      end
    end
  end
end
