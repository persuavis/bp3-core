# frozen_string_literal: true

module Bp3
  module Core
    module Rqid
      extend ActiveSupport::Concern

      mattr_accessor :global_request_state_class_name, :global_request_state_method

      # The records of the request a row was written in, found through the rqid they share. Sharing a
      # request is not belonging to it, so Tenantable leaves them out of its site check.
      REQUEST_ASSOCIATIONS = %i[original_request original_response original_visit].freeze

      def self.global_request_state_class
        global_request_state_class_name.constantize
      end

      included do
        before_create :set_rqid

        # CAUTION: these are defined as belongs_to, therefore returning one record. However, it is possible
        # that multiple such records exist
        belongs_to :original_request, class_name: 'Inbound::Request',
                                      foreign_key: :rqid, primary_key: :rqid, optional: true
        belongs_to :original_response, class_name: 'Inbound::Response',
                                       foreign_key: :rqid, primary_key: :rqid, optional: true
        belongs_to :original_visit, class_name: 'Visit',
                                    foreign_key: :rqid, primary_key: :rqid, optional: true
      end

      private

      def set_rqid
        return if rqid

        self.rqid = rqid_from_global_state
      end

      def rqid_from_global_state
        Bp3::Core::Rqid.global_request_state_class.send(Bp3::Core::Rqid.global_request_state_method)
      end
    end
  end
end
