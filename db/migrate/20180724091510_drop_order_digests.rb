class DropOrderDigests < ActiveRecord::Migration
  def self.up
	drop_table :order_digest_requests
	drop_table :order_digest_offers
  end

  def self.down
    create_table :order_digest_requests do |t|
      t.decimal :price_digest, :precision => 32, :scale => 16
      t.integer :amount
      t.integer :count_number
      t.integer :currency

      t.timestamps
    end
	
    create_table :order_digest_offers do |t|
      t.integer :ask
      t.decimal :price_digest, :precision => 32, :scale => 16
      t.integer :amount
      t.integer :count_number
      t.integer :currency

      t.timestamps
    end	
  end

end
