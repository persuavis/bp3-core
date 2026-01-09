# frozen_string_literal: true

module Bp3
  module Core
    # Bp3::Core::Test provides a convenience class for testing Bp3::Core
    class Test
      class SystemLogger
        @log_count = 0

        def self.log_message(level:, key:, message:, details:)
          puts "Test:SystemLogger: #{level} #{key} #{message} #{details}"
          add_count
        end

        def self.add_count
          @log_count += 1
        end

        class << self
          attr_reader :log_count
        end
      end

      class ExceptionLogger
        @log_count = 0

        def self.log_exception(exception, site:, key:, details:)
          puts "Test:ExceptionLogger: #{site&.display_name} #{key} #{exception.message} #{details}"
          add_count
        end

        def self.add_count
          @log_count += 1
        end

        class << self
          attr_reader :log_count
        end
      end

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

      # to test SystemLogs
      include SystemLogs # to use log methods on an instance
      extend SystemLogs # to use log methods on the class

      # to test Tenantable
      # first define this:
      def self.connection; end
      # then include Tenantable
      include Tenantable
    end
  end
end
