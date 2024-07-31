# frozen_string_literal: true

module Bp3
  module Core
    # rubocop:disable Metrics/ModuleLength
    module Actions
      extend ActiveSupport::Concern

      # include FeatureFlags # do not include here
      # include Settings # do not include here

      included do
        # Order matters! don't change it. These prepends are from last to first
        prepend_before_action :check_tenant
        prepend_before_action :check_workspace
        prepend_before_action :check_site
        prepend_before_action :set_rqid
        before_action :set_paper_trail_whodunnit # uses user_for_paper_trail
        before_action :find_or_create_user_agent
        before_action :create_request_record
        before_action :check_site_mode

        before_action :set_global_request_state
      end

      class_methods do
        # To support Devise this needs to be a class method
        def default_url_options(options = {})
          out = super().merge(options)
          ignore_locale = ENV.fetch('IGNORE_LOCALIZATION', false)
          return out if ignore_locale

          out.merge(locale: I18n.locale)
        end
      end

      private

      def set_global_request_state
        grsc.inbound_request = @global_request
        grsc.current_user = current_user
        grsc.current_admin = current_admin
        grsc.current_root = current_root
        grsc.locale = I18n.locale
        grsc.view_context = view_context
      end

      def set_rqid
        grsc.request_id = global_rqid
      end

      def global_rqid
        @global_rqid ||= request.request_id || SecureRandom.uuid
      end

      def create_request_record
        return if do_not_track
        return unless create_request_record_is_on?

        # Apparently, we can receive multiple requests with the same request_id
        # TODO: relax the uniqueness constraint instead of re-using the existing record
        @global_request = Inbound::Request.find_by(id: request.request_id)
        return @global_request if @global_request

        @global_request = Inbound::Request.create!(id: global_rqid,
                                                   url: request.url,
                                                   ip_address: request.ip,
                                                   referer: request.referer,
                                                   inbound_user_agent: @global_user_agent,
                                                   sites_site: current_site)
      end

      def find_or_create_user_agent
        return if do_not_track

        user_agent = request.user_agent.presence || 'user-agent-is-blank'
        @global_user_agent = Inbound::UserAgent.find_or_create_by!(user_agent:)
      rescue ActiveRecord::RecordInvalid
        # probably hit a race condition. Try again and log
        @global_user_agent = Inbound::UserAgent.find_by!(user_agent:)
        message = "User agent already existed (#{@global_user_agent.id}/#{user_agent})"
        log_warn(key: 'find_or_create_user_agent', message:)
        @global_user_agent
      end

      def check_site
        current_site || create_site
        grsc.current_site = current_site
      end

      def current_site
        return @current_site if @current_site

        @current_site = request.request_site
      end

      def create_site
        @current_site = Sites::Site.create!(request_domain:)
      end

      # TODO: cache the workspace/regex list
      def check_workspace
        current_workspace || create_workspace
        grsc.current_workspace = current_workspace
      end

      # TODO: move (some of) this into Workspace
      def current_workspace
        return @current_workspace if @current_workspace
        return nil if current_site.nil?

        current_site.workspaces.find_each do |workspace|
          if workspace.has_pattern_match?(request.subdomain)
            @current_workspace = workspace
            return @current_workspace
          end
        end
      end

      # TODO: move (some of) this into Workspace
      def create_workspace
        workspace_type = Workspaces::WorkspaceType
                         .find_or_create_by!(sites_site: current_site, name: 'default')
        @current_workspace = Workspaces::Workspace.create!(sites_site: current_site,
                                                           name: 'default', match_pattern: '\A.*\z',
                                                           workspaces_workspace_type: workspace_type)
      end

      def check_tenant
        current_tenant || create_tenant
        grsc.current_tenant = current_tenant
      end

      def current_tenant
        return @current_tenant if @current_tenant

        @current_tenant = current_site.tenants.find_by(tenantable:)
      end

      def create_tenant
        @current_tenant = Tenant.create!(sites_site: current_site, tenantable:)
      end

      def tenantable
        @tenantable ||= multi_tenant_is_on? ? current_workspace : current_site
      end

      def request_domain
        @request_domain ||= DomainExtractor.extract_domain(request_host) || request.domain || request_host
      end

      def request_host
        request.normalized_host
      end

      def request_subdomain
        return @request_subdomain if @request_subdomain

        subdomain = request_host.gsub(/#{request_domain}\z/, '')
        subdomain = subdomain[0..-2] if subdomain.ends_with?('.')
        @request_subdomain = subdomain
      end

      def info_for_paper_trail
        state = grsc.new
        {
          rqid: global_rqid,
          sites_site_id: state.current_site&.id,
          tenant_id: state.current_tenant&.id,
          workspaces_workspace_id: state.current_workspace&.id,
          root_id: state.current_root&.id,
          sites_admin_id: state.current_admin&.id,
          users_user_id: state.current_user&.id
        }
      end

      def set_ransack_auth_object
        current_root || current_admin || current_user
      end

      # used by set_paper_trail_whodunnit
      def user_for_paper_trail
        current_root || current_admin || current_user || current_visitor || 'guest'
      end

      def pundit_user
        UserContext.new
      end

      def either_site
        grsc.either_site
      end

      def check_site_mode
        return unless current_site.sites_modes.enabled.timely.any?

        current_site.sites_modes.enabled.timely.each do |mode|
          next unless mode.name == 'maintenance'

          @resource = @sites_mode = mode
          @content = @resource.content
          @content_format = @resource.content_format
          render template: 'sites/modes/maintenance'
          break
        end
      end

      def grsc
        @grsc ||= Bp3::Core::Rqid.global_request_state_class
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
