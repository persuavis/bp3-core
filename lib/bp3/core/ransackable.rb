# frozen_string_literal: true

module Bp3
  module Ransackable
    extend ActiveSupport::Concern

    class_methods do
      def ransackable_fields(auth_object = nil)
        fields =
          ransackable_attributes(auth_object) +
            ransackable_associations(auth_object) +
            ransackable_scopes(auth_object)
        fields.map(&:to_sym).uniq
      end

      def ransackable_attributes(_auth_object = nil)
        except = %w[config config_id settable settable_id]
        column_names.map(&:to_s) - except
      end

      def ransackable_associations(_auth_object = nil)
        except = %w[config settable]
        reflect_on_all_associations.map(&:name).map(&:to_s) - except
      end

      def ransackable_scopes(_auth_object = nil)
        []
      end

      def ransortable_attributes(auth_object = nil)
        ransackable_attributes(auth_object)
      end
    end
  end
end
