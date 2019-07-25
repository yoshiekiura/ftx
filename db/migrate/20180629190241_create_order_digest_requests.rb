class CreateOrderDigestRequests < ActiveRecord::Migration
  def self.up
    create_table :order_digest_requests do |t|
      t.decimal :price_digest, :precision => 32, :scale => 16
      t.integer :amount
      t.integer :count_number
      t.integer :currency

      t.timestamps
    end
  end

  def self.down
    drop_table :order_digest_requests
  end

end
