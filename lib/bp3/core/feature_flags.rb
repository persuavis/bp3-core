# frozen_string_literal: true

module Bp3
  module Core
    module FeatureFlags
      extend ActiveSupport::Concern

      def efcfon?(flag, ref: nil, default: nil)
        ef = efon(flag, ref:, default: nil)
        cf = cfon(flag, ref:, default: nil)

        if ef.nil? && cf.nil?
          default || false
        elsif ef.nil?
          cf
        elsif cf.nil?
          ef
        else
          cf || ef
        end
      end

      def efon(flag, ref: nil, default: nil)
        Feature::Enabler.on(flag, enablable: ref, default:)
      end

      # An explicit false wins over the default; the default applies only when the flag is not set
      def efon?(flag, ref: nil, default: nil)
        efon(flag, ref:, default:) || false
      end

      def cfon(flag, ref: nil, default: nil)
        value = ref&.configs&.[](flag)
        value.nil? ? default : value
      end

      # An explicit false wins over the default; the default applies only when the config is not set
      def cfon?(flag, ref: nil, default: nil)
        cfon(flag, ref:, default:) || false
      end
    end
  end
end
