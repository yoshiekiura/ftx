class ChangeStratumOperations < ActiveRecord::Migration
  def self.up
	drop_table :stratum_operations

    create_table :stratum_operations do |t|
	  t.string :operation_status
	  t.string :operation_type	
	  t.integer :operation_ts
	  t.integer :operation_upd_ts
	  t.string :cointrade_state
	  
	  t.string :direction_type
	  t.string :dest_type
	  t.string :dest_type_data
	  
      t.integer :operation_id
	  t.integer :operation_eid
	  t.string :operation_etxid
	  
	  t.decimal :operation_amount, :precision => 32, :scale => 16
	  t.decimal :operation_tamount, :precision => 32, :scale => 16
	  t.decimal :operation_fee, :precision => 32, :scale => 16	 
	  
	  t.string :currency
	  t.string :currency_unit
	  t.string :currency_type  
	  t.decimal :currency_usdtrate, :precision => 32, :scale => 16
	  
	  t.integer :wallet_id	  
	  t.integer :wallet_eid
	  t.integer :wallet_group_id
	  t.integer :wallet_group_eid	  
	  t.string :wallet_label
	  t.string :wallet_type	  	 
	    
	  t.string :operation_desc
	  t.integer :operation_conf
	  t.integer :operation_confreq
	  t.string :operation_info 
	  
      t.timestamps
    end
	
	add_index :stratum_operations, :operation_id
	add_index :stratum_operations, :operation_eid
	add_index :stratum_operations, :operation_ts
	add_index :stratum_operations, :operation_upd_ts
	add_index :stratum_operations, :wallet_eid
	add_index :stratum_operations, :currency
	add_index :stratum_operations, :operation_type
	add_index :stratum_operations, :operation_etxid, unique: true
	add_index :stratum_operations, :operation_status
	add_index :stratum_operations, :cointrade_state
	
  end
  
  def self.down
    drop_table :stratum_operations
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
