class AddTxidByUserToDeposit < ActiveRecord::Migration
  def change
    add_column :deposits, :txid_by_user, :string
  end
end
