# frozen_string_literal: true

module Bp3
  # Bp3::Test provides a convenience class for testing Bp3::Core
  class Test
    include Core

    # to test Ransackable
    def self.column_names
      %i[id name]
    end

    def self.reflect_on_all_associations
      []
    end
  end
end
