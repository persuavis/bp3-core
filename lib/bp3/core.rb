# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/module/attribute_accessors'
require_relative 'core/version'
require_relative 'core/ransackable'

module Bp3
  # Bp3::Core provides core includes
  module Core
    extend ActiveSupport::Concern

    include Ransackable

    class Error < StandardError; end
  end
end
