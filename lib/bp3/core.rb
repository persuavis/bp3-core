# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/module/attribute_accessors'

require_relative 'core/actions'
require_relative 'core/cookies'
require_relative 'core/displayable'
require_relative 'core/feature_flags'
require_relative 'core/ransackable'
require_relative 'core/settings'
require_relative 'core/system_logs'
require_relative 'core/tenantable'
require_relative 'core/rqid'
require_relative 'core/sqnr'
require_relative 'core/version'

module Bp3
  module Core
  end
end
