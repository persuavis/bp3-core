# frozen_string_literal: true

module Bp3
  module Core
    module Cookies
      extend ActiveSupport::Concern

      included do
        attr_reader :current_visitor

        before_action :check_visitor_cookie
      end

      VISITOR_COOKIE_NAME_PREFIX = '_bp3_visitor'
      DO_NOT_TRACK_VALUE = 'do_not_track'

      private

      def do_not_track
        return @do_not_track unless @do_not_track.nil? # could be set to true or false already

        cookie_value = cookies[new_visitor_cookie_name]
        @do_not_track = cookie_value == DO_NOT_TRACK_VALUE
        reset_session if @do_not_track
        @do_not_track
      end

      def set_do_not_track
        # this replaces the signed temporary cookie with an unsigned, permanent cookie
        cookies.permanent[new_visitor_cookie_name] = DO_NOT_TRACK_VALUE
      end

      def start_tracking
        return unless do_not_track

        cookies.delete(visitor_cookie_name)
        @do_not_track = false
        check_visitor_cookie
      end

      def check_visitor_cookie
        switch_old_to_new
        check_new_visitor_cookie
      end

      def switch_old_to_new
        cookie_value = cookies.signed[visitor_cookie_name]
        return if cookie_value.blank?

        _sites_site_id, _tenant_id, identification = cookie_value&.split('/')

        message = "check_visitor_cookie: switching to new visitor_cookie for #{identification}"
        Rails.logger.debug message
        cookies.delete(visitor_cookie_name)
        cookies.signed[new_visitor_cookie_name] = {
          value: identification,
          expires: 365.days.from_now
        }
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def check_old_visitor_cookie
        cookie_value = cookies.signed[visitor_cookie_name]
        return if cookie_value.blank? && do_not_track

        sites_site_id, tenant_id, identification = cookie_value&.split('/')
        if sites_site_id && sites_site_id != grsc.current_site.id
          Rails.logger.warn { "check_visitor_cookie: site mismatch! (#{sites_site_id} and #{grsc.current_site.id}" }
        end
        if tenant_id && tenant_id != grsc.current_tenant.id
          Rails.logger.warn { "check_visitor_cookie: tenant mismatch! (#{tenant_id} and #{grsc.current_tenant.id}" }
        end
        visitor = Users::Visitor.find_by(sites_site_id:, tenant_id:, identification:)
        if visitor.nil?
          visitor = create_visitor
          message = "check_visitor_cookie: create_visitor #{visitor.id} and create #{visitor_cookie_name} cookie"
          Rails.logger.debug message
          cookies.signed[visitor_cookie_name] = {
            value: visitor.scoped_identification,
            expires: 365.days.from_now
          }
        end
        @current_visitor = grsc.current_visitor = visitor
        Rails.logger.debug do
          "check_visitor_cookie: cookie[#{visitor_cookie_name}]=#{cookies.signed[visitor_cookie_name]}"
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def check_new_visitor_cookie
        cookie_value = cookies.signed[new_visitor_cookie_name]
        return if cookie_value.blank? && do_not_track

        identification = cookie_value
        sites_site_id = grsc.current_site_id
        tenant_id = grsc.current_tenant_id
        visitor = Users::Visitor.find_by(sites_site_id:, tenant_id:, identification:)
        if visitor.nil?
          visitor = create_visitor
          message = "check_visitor_cookie: create_visitor #{visitor.id} and create #{new_visitor_cookie_name} cookie"
          Rails.logger.debug message
          cookies.signed[new_visitor_cookie_name] = {
            value: visitor.identification,
            expires: 365.days.from_now
          }
        end
        @current_visitor = grsc.current_visitor = visitor
        Rails.logger.debug do
          "check_visitor_cookie: cookie[#{new_visitor_cookie_name}]=#{cookies.signed[new_visitor_cookie_name]}"
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def visitor_cookie_name
        @visitor_cookie_name ||= "#{VISITOR_COOKIE_NAME_PREFIX}_#{cookie_site_id}_#{cookie_tenant_id}"
      end

      def new_visitor_cookie_name
        VISITOR_COOKIE_NAME_PREFIX
      end

      def create_visitor
        Users::Visitor.create!(sites_site: grsc.current_site,
                               tenant: grsc.current_tenant,
                               workspaces_workspace: grsc.current_workspace,
                               identification: SecureRandom.uuid)
      end

      def cookie_site_id
        grsc.current_site.id[0..7]
      end

      def cookie_tenant_id
        grsc.current_tenant.id[0..7]
      end
    end
  end
end
