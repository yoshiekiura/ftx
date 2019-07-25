class AddTxoutToWithdraws < ActiveRecord::Migration
  def change
    add_column :withdraws, :txout, :integer
    add_index :withdraws, [:txid, :txout]
	
	ActiveRecord::Base.connection.execute("UPDATE withdraws SET withdraws.txout = withdraws.txid 
	                                       WHERE withdraws.txid IS NOT NULL 
										     AND withdraws.type != 'Withdraws::Bank';")
	
	ActiveRecord::Base.connection.execute("UPDATE withdraws 
                                           INNER JOIN stratum_events ON stratum_events.operation_id = withdraws.txid 
										              AND withdraws.txid IS NOT NULL 
													  AND withdraws.type != 'Withdraws::Bank'
                                           SET withdraws.txid = stratum_events.operation_etxid")
  end
end
