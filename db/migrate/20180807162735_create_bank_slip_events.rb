class CreateBankSlipEvents < ActiveRecord::Migration
  def change
    create_table :bank_slip_events do |t|
      t.string :operation_txid
      t.string :operation_status
      t.string :operation_type
      t.decimal :operation_amount, :precision => 32, :scale => 16
      t.datetime :confirmation_at
      t.timestamps
    end
  end
end
