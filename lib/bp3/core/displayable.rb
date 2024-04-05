# frozen_string_literal: true

module Bp3
  module Core
    module Displayable
      extend ActiveSupport::Concern

      def to_dom_id
        ActionView::RecordIdentifier.dom_id(self)
      end

      def display_name
        admin_display_name
      end

      def admin_display_name
        "#{self.class.name.split('::').last} #{id}"
      end

      def filtered_attributes
        filter_object_fields if respond_to?(:object)
        filter_attributes
      end

      def i18n_key
        self.class.i18n_key
      end

      private

      def version_filter_mask
        '[FILTERED][DC]'
      end

      def filter_attributes
        filter.filter(attributes)
      end

      def filter_object_fields
        self.object = filter.filter(object) if object.present?
        return if object_changes.blank?

        filtered_object_changes = filter.filter(object_changes)
        filtered_object_changes.each_key do |key|
          if filtered_object_changes[key] == version_filter_mask
            filtered_object_changes[key] =
              mark_changes_as_filtered(key)
          end
        end
        self.object_changes = filtered_object_changes
      end

      def filter
        return @filter if @filter

        filters = Rails.application.config.filter_parameters
        @filter = ActiveSupport::ParameterFilter.new(filters, mask: version_filter_mask)
      end

      def mark_changes_as_filtered(key)
        change = object_changes[key]
        change[0] = version_filter_mask if change[0].present?
        change[1] = version_filter_mask if change[1].present?
        change
      end

      class_methods do
        def i18n_key
          name.downcase.gsub('::', '/')
        end
      end
    end
  end
end
