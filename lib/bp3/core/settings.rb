# frozen_string_literal: true

module Bp3
  module Core
    module Settings
      extend ActiveSupport::Concern

      def create_request_record_is_on?
        efcfon?(:create_request_record, ref: current_site, default: true)
      end

      def multi_tenant_is_on?
        efcfon?('multi-tenant', ref: current_site, default: false)
      end
    end
  end
end
