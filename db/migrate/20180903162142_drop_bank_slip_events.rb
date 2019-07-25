class DropBankSlipEvents < ActiveRecord::Migration
  def change
    drop_table :bank_slip_events
  end
end
