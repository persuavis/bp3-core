# frozen_string_literal: true

module Bp3
  module Core
    # Bp3::Core::Test provides a convenience class for testing Bp3::Core
    class Test
      # to test Ransackable
      include Ransackable

      def self.column_names
        %i[id name]
      end

      def self.reflect_on_all_associations
        []
      end

      # to test Cookies
      # first define this:
      def self.before_action(_method_name); end
      # then include Cookies
      include Cookies

      # to test Displayable
      include Displayable

      # to test FeatureFlags
      include FeatureFlags

      # to test Rqid
      # first define this:
      def self.before_create(_method_name); end
      def self.belongs_to(_association, **options); end
      def self.scope(_scope_name, _lambda); end
      # then include Rqid
      include Rqid

      # to test Sqnr
      include Sqnr

      # to test Tenantable
      # first define this:
      def self.connection; end
      # then include Tenantable
      include Tenantable
    end
  end
end
