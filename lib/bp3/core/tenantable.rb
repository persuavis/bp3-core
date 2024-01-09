# frozen_string_literal: true

module Bp3
  module Core
    module Tenantable
      extend ActiveSupport::Concern

      included do
        # call connection to make sure the db meta data has been loaded
        ignore_notifications_string = (ENV['IGNORE_NOTIFICATIONS'] || '').strip
        connection if ignore_notifications_string.empty?
      end

      private

      def set_sites_site_id
        return if sites_site_id || sites_site

        self.sites_site_id = GlobalRequestState.either_site_id
      end

      def set_tenant_id
        return if tenant_id || tenant

        self.tenant_id = GlobalRequestState.either_tenant_id
      end

      def tenant_matches_site
        tid = tenant_id || tenant&.id
        return if tid.nil?

        tenant ||= Tenant.find(tid)
        return if (sites_site_id || sites_site&.id) == tenant.sites_site_id

        errors.add(:tenant, :must_match_site)
      end

      def set_workspaces_workspace_id
        return if workspaces_workspace_id || workspaces_workspace

        self.workspaces_workspace_id = GlobalRequestState.either_workspace_id
      end

      def workspaces_workspace_matches_site
        wid = workspaces_workspace_id || workspaces_workspace&.id
        return if wid.nil?

        workspaces_workspace ||= Workspaces::Workspace.find(wid)
        return if (sites_site_id || sites_site&.id) == workspaces_workspace.sites_site_id

        errors.add(:workspaces_workspace, :must_match_site)
      end

      # rubocop:disable: Metrics/BlockLength
      class_methods do
        def configure_tenancy(tenancy_configuration = {})
          @tenancy_configuration = default_configuration.merge(tenancy_configuration)
          may_belong_to_site
          may_belong_to_tenant
          may_belong_to_workspace
        rescue ActiveRecord::StatementInvalid, PG::UndefinedTable => e
          Rails.logger.error { "ERROR in configure_tenancy: #{e.message}" }
          # log_exception(e) # infinite loop
        end

        def may_belong_to_site
          column = columns.detect { |c| c.name == 'sites_site_id' }
          return if column.nil?

          @tenancy_configuration[:belongs_to_site] = true
          optional = column.null
          belongs_to(:sites_site, class_name: 'Sites::Site', optional:)
          alias_method :site, :sites_site
          alias_method :site=, :sites_site=

          before_validation :set_sites_site_id

          default_scope lambda {
            site = GlobalRequestState.either_site
            site = nil if GlobalRequestState.current_root
            where(sites_site_id: site.id) if site
          }
        end

        # rubocop:disable Metrics/MethodLength
        def may_belong_to_tenant
          column = columns.detect { |c| c.name == 'tenant_id' }
          return if column.nil?

          @tenancy_configuration[:belongs_to_tenant] = true
          optional = column.null
          belongs_to(:tenant, optional:)

          before_validation :set_tenant_id

          validate :tenant_matches_site

          default_scope lambda {
            site = GlobalRequestState.either_site
            site = nil if GlobalRequestState.current_root
            tenant = GlobalRequestState.either_tenant
            tenant = nil if GlobalRequestState.either_admin
            if site && tenant # for non admins (i.e. users)
              where(sites_site_id: site.id, tenant_id: tenant.id)
            elsif site # for site admins
              where(sites_site_id: site.id)
            elsif tenant
              raise RuntimeError # where(tenant_id: tenant.id)
            end
          }
        end
        # rubocop:enable Metrics/MethodLength

        def may_belong_to_workspace
          column = columns.detect { |c| c.name == 'workspaces_workspace_id' }
          return if column.nil?

          @tenancy_configuration[:belongs_to_workspace] = true
          optional = column.null
          belongs_to(:workspaces_workspace, class_name: 'Workspaces::Workspace', optional:)
          alias_method :workspace, :workspaces_workspace
          alias_method :workspace=, :workspaces_workspace=

          before_validation :set_workspaces_workspace_id

          validate :workspaces_workspace_matches_site
        end

        def default_configuration
          {
            site_presence: :db,
            tenant_presence: :db,
            workspace_presence: :db,
            site_source: :either_site,
            tenant_source: :either_tenant,
            workspace_source: :either_workspace
          }
        end
      end
      # rubocop:disable: Metrics/BlockLength
    end
  end
end
