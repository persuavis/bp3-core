# frozen_string_literal: true

module Bp3
  module Core
    module Tenantable
      extend ActiveSupport::Concern

      # The belongs_to associations with a site check of their own
      SITE_CHECKED_ASSOCIATIONS = %i[sites_site tenant workspaces_workspace].freeze

      # The application's request state, the Bp3::RequestState::Base subclass Bp3::Core::Rqid is
      # configured with
      def self.global_request_state
        Bp3::Core::Rqid.global_request_state_class
      end

      # How far a default scope reaches is decided by the primary login, the request state's
      # current_login: the least privileged one signed in. A root or an admin signed in beside a less
      # privileged login has that login's reach rather than their own.
      def self.reaches_every_site?(state = global_request_state)
        login = state.current_login
        !login.nil? && login == state.current_root
      end

      def self.reaches_every_tenant?(state = global_request_state)
        login = state.current_login
        !login.nil? && (login == state.current_root || login == state.current_admin)
      end

      included do
        # call connection to make sure the db meta data has been loaded
        ignore_notifications_string = (ENV['IGNORE_NOTIFICATIONS'] || '').strip
        connection if ignore_notifications_string.empty?
      end

      private

      def set_sites_site_id
        return if sites_site_id || sites_site

        self.sites_site_id = Bp3::Core::Tenantable.global_request_state.either_site_id
      end

      def set_tenant_id
        return if tenant_id || tenant

        self.tenant_id = Bp3::Core::Tenantable.global_request_state.either_tenant_id
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

        self.workspaces_workspace_id = Bp3::Core::Tenantable.global_request_state.either_workspace_id
      end

      def workspaces_workspace_matches_site
        wid = workspaces_workspace_id || workspaces_workspace&.id
        return if wid.nil?

        workspaces_workspace ||= Workspaces::Workspace.find(wid)
        return if (sites_site_id || sites_site&.id) == workspaces_workspace.sites_site_id

        errors.add(:workspaces_workspace, :must_match_site)
      end

      # Every record the row belongs to that has a site must have the row's site. A root's default scope
      # reaches every site, so an id from another site is found and would otherwise be stored. Checked
      # when the foreign key, or a polymorphic type, is set or changed, so an unchanged row costs nothing.
      def belongs_to_records_match_site
        site_id = sites_site_id || sites_site&.id
        return if site_id.nil?

        self.class.reflect_on_all_associations(:belongs_to).each do |reflection|
          next if SITE_CHECKED_ASSOCIATIONS.include?(reflection.name) || !belonged_record_changed?(reflection)

          belonged_site_id = belonged_record_site_id(reflection)
          next if belonged_site_id.nil? || belonged_site_id == site_id

          errors.add(reflection.name, :must_match_site)
        end
      end

      def belonged_record_changed?(reflection)
        attribute_changed?(reflection.foreign_key.to_s) ||
          (reflection.polymorphic? && attribute_changed?(reflection.foreign_type.to_s)) ||
          association(reflection.name).target&.new_record?
      end

      # The site of the record the association points to, nil when that record has no site
      def belonged_record_site_id(reflection)
        loaded = association(reflection.name)
        if loaded.loaded? && !loaded.stale_target? && loaded.target
          return loaded.target.respond_to?(:sites_site_id) ? loaded.target.sites_site_id : nil
        end

        klass = belonged_record_class(reflection)
        id = self[reflection.foreign_key]
        return if klass.nil? || id.nil? || !klass.column_names.include?('sites_site_id')

        klass.unscoped.where(klass.primary_key => id).pick(:sites_site_id)
      end

      def belonged_record_class(reflection)
        klass = reflection.polymorphic? ? self[reflection.foreign_type]&.safe_constantize : reflection.klass
        klass if klass.is_a?(Class) && klass < ActiveRecord::Base
      rescue NameError
        nil
      end

      # rubocop:disable-next Metrics/BlockLength
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

          validate :belongs_to_records_match_site

          default_scope lambda {
            site = Bp3::Core::Tenantable.global_request_state.either_site
            site = nil if Bp3::Core::Tenantable.reaches_every_site?
            where(sites_site_id: site.id) if site
          }
        end

        # rubocop:disable-next Metrics/MethodLength
        def may_belong_to_tenant
          column = columns.detect { |c| c.name == 'tenant_id' }
          return if column.nil?

          @tenancy_configuration[:belongs_to_tenant] = true
          optional = column.null
          belongs_to(:tenant, optional:)

          before_validation :set_tenant_id

          validate :tenant_matches_site

          default_scope lambda {
            site = Bp3::Core::Tenantable.global_request_state.either_site
            site = nil if Bp3::Core::Tenantable.reaches_every_site?
            tenant = Bp3::Core::Tenantable.global_request_state.either_tenant
            tenant = nil if Bp3::Core::Tenantable.reaches_every_tenant?
            if site && tenant # for non admins (i.e. users)
              where(sites_site_id: site.id, tenant_id: tenant.id)
            elsif site # for site admins
              where(sites_site_id: site.id)
            elsif tenant
              raise RuntimeError # where(tenant_id: tenant.id)
            end
          }
        end

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
    end
  end
end
