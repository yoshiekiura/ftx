module Deposits
  module Slipable
    extend ActiveSupport::Concern

    included do
      validates :fund_extra, :fund_uid, :amount, presence: true
      delegate :accounts, to: :channel
    end
  end
end
