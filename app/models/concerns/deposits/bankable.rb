module Deposits
  module Bankable
    extend ActiveSupport::Concern

    included do
      validates :amount, presence: true
      delegate :accounts, to: :channel
    end
  end
end
