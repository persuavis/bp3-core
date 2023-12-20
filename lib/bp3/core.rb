# frozen_string_literal: true

require 'active_support/concern'
require_relative "core/version"
require_relative 'core/ransackable'

module Bp3
  module Core
    extend ActiveSupport::Concern

    include Ransackable

    class Error < StandardError; end
    # Your code goes here...
  end
end
