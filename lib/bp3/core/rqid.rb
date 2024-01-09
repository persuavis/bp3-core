# frozen_string_literal: true

module Bp3
  module Core
    module Rqid
      extend ActiveSupport::Concern

      mattr_accessor :global_request_state_class_name, :global_request_state_method

      def self.global_request_state_class
        @@global_request_state_class ||= global_request_state_class_name.constantize # rubocop:disable Style/ClassVars
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

      # class_methods do
      #   def global_request_state_class
      #     @@global_request_state_class ||= global_request_state_class_name.constantize
      #   end
      # end

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
