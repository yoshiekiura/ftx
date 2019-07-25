module Withdraws
  module Bankable
    extend ActiveSupport::Concern

    def set_fee

      fund_name = fund_extra.present? ? fund_extra : FundSource.find_by(id: fund_source_id).extra
      if !member.admin? and !member.financial?
        banks_all = "bank".camelize.constantize.all
        bank_selected = banks_all.select {|bank| bank[:code].to_s == fund_name}

        fee = bank_selected[0][:fee_percent]
        real_fee = (self.sum * fee) / 100
        self.fee = real_fee + bank_selected[0][:fee_brute].to_d

      else
        self.fee = 0
      end

    end

    included do
      validates_presence_of :fund_extra

      delegate :name, to: :member, prefix: true

      alias_attribute :remark, :id
    end

  end
end
