# frozen_string_literal: true

module Bp3
  module Core
    module Sqnr
      extend ActiveSupport::Concern

      included do
        scope :sqnr, -> { order(sqnr: :asc) }
        scope :rnqs, -> { order(sqnr: :desc) }
      end

      class_methods do
        def use_sqnr_for_ordering
          self.implicit_order_column = :sqnr
        end
      end
    end
  end
end
