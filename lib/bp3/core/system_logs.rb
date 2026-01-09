# frozen_string_literal: true

require 'logger'

module Bp3
  module Core
    module SystemLogs
      extend ActiveSupport::Concern

      SYSTEM_LOG_DEFAULTS = { log_to_db: true, log_to_io: true }.freeze

      mattr_accessor :system_exception_name, :system_log_name

      def self.system_exception_class
        @@system_exception_class ||= system_exception_name.constantize # rubocop:disable Style/ClassVars
      end

      def self.system_log_class
        @@system_log_class ||= system_log_name.constantize # rubocop:disable Style/ClassVars
      end

      # Class methods for use in contexts without instance methods
      module ClassMethods
        # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
        def log(level:, key:, message: nil, exception: nil, site: nil, details: {}, **system_log_options)
          system_log_options = SYSTEM_LOG_DEFAULTS.dup.merge(system_log_options)
          record = nil
          if exception
            if system_log_options[:log_to_io]
              rails_logger.debug do
                "SystemLogs, #{level}, #{key}, #{exception.message}"
              end
            end
            record = exception_logger.log_exception(exception, site:, key:, details:) if system_log_options[:log_to_db]
          end
          return record if (message || '').strip == ''

          rails_logger.debug { "SystemLogs, #{level}, #{key}, #{message}" } if system_log_options[:log_to_io]
          begin
            system_logger.log_message(level:, key:, message:, details:) if system_log_options[:log_to_db]
          rescue StandardError => e
            rails_logger.error { "SystemLogs.log failed: #{e.message}" }
            nil
          end
        end
        # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

        def log_debug(key:, message:, details: {}, **system_log_options)
          log(level: 'debug', key:, message:, details:, **system_log_options)
        end

        def log_info(key:, message:, details: {}, **system_log_options)
          log(level: 'info', key:, message:, details:, **system_log_options)
        end

        def log_warn(key:, message:, details: {}, **system_log_options)
          log(level: 'warn', key:, message:, details:, **system_log_options)
        end

        def log_error(key:, message:, details: {}, **system_log_options)
          log(level: 'error', key:, message:, details:, **system_log_options)
        end

        def log_exception(exception, key:, details: {}, **system_log_options)
          if exception.nil?
            rails_logger.error { "SystemLogs, #{key}, nil exception logged" }
            return nil
          end
          log(level: 'exception', key:, exception:, details:, **system_log_options)
        end

        def rails_logger
          return Rails.logger if defined?(Rails)

          ::Logger.new($stdout, level: Logger::ERROR)
        end

        def system_logger
          ::Bp3::Core::SystemLogs.system_log_class
        end

        def exception_logger
          ::Bp3::Core::SystemLogs.system_exception_class
        end
      end

      # rubocop:disable Metrics/ParameterLists
      def log(level:, key:, message: nil, exception: nil, site: nil, details: {}, **system_log_options)
        SystemLogs.log(level:, key:, message:, exception:, site:, details:, **system_log_options)
      end
      # rubocop:enable Metrics/ParameterLists

      def log_debug(key:, message:, details: {}, **system_log_options)
        SystemLogs.log_debug(key:, message:, details:, **system_log_options)
      end

      def log_info(key:, message:, details: {}, **system_log_options)
        SystemLogs.log_info(key:, message:, details:, **system_log_options)
      end

      def log_warn(key:, message:, details: {}, **system_log_options)
        SystemLogs.log_warn(key:, message:, details:, **system_log_options)
      end

      def log_error(key:, message:, details: {}, **system_log_options)
        SystemLogs.log_error(key:, message:, details:, **system_log_options)
      end

      def log_exception(exception, key:, details: {}, **system_log_options)
        SystemLogs.log_exception(exception, key:, details:, **system_log_options)
      end

      # Extend self to make ClassMethods available directly on SystemLogs module
      extend ClassMethods
    end
  end
end
