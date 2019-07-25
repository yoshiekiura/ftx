class CreateStratumOperations < ActiveRecord::Migration
  def change
    create_table :stratum_operations do |t|
      t.integer :stratum_id
	  t.integer :eid
	  t.integer :receive_at
	  t.string :desc
	  t.integer :wallet_id
	  t.integer :wallet_eid
	  t.string :wallet_label
	  t.string :currency
	  t.decimal :amount, :precision => 32, :scale => 16
	  t.string :operation	  
	  t.string :etxid
	  t.string :stratum_state
	  t.string :state
	  t.string :address
	
      t.timestamps
    end
	
	add_index :stratum_operations, :stratum_id
	add_index :stratum_operations, :eid
	add_index :stratum_operations, :receive_at
	add_index :stratum_operations, :wallet_eid
	add_index :stratum_operations, :currency
	add_index :stratum_operations, :operation
	add_index :stratum_operations, :etxid, unique: true
	add_index :stratum_operations, :stratum_state
	add_index :stratum_operations, :state
  end
end
