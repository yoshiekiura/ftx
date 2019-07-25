module FundSourceable
  extend ActiveSupport::Concern

  included do
    attr_accessor :fund_source_id
    before_validation :set_fund_source_attributes, on: :create
    validates :fund_source_id, presence: true, on: :create
  end

  def set_fund_source_attributes
    if fund_source_id == 0
      self.fund_extra = self.type
      self.fund_uid = self.type
      self.txid = "#{(Time.now.to_f * 1000).to_i.to_s}#{self.amount.to_i.to_s}"
    else
      if fs = FundSource.find_by(id: fund_source_id)
        self.fund_extra = fs.extra
        self.fund_uid = fs.uid.strip
      end
    end
  end
end
