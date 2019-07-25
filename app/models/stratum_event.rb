class StratumEvent < ActiveRecord::Base
  extend Enumerize

  STRATUM_STATE = [:new, :processing, :done, :failed, :canceled]
  enumerize :operation_status, in: STRATUM_STATE, scope: true

  COINTRADE_STATE = [:waiting, :processing, :done, :failed]
  enumerize :cointrade_state, in: COINTRADE_STATE, scope: true

  validates_presence_of :operation_id
  validates_presence_of :dest_type_data

  belongs_to :payment_address, foreign_key: 'address', primary_key: 'address'
  has_one :account, through: :payment_address
  has_one :member, through: :account

end
