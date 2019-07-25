class RemoveAskFieldFromOrderDigestOffersTable < ActiveRecord::Migration
  def up
    remove_column :order_digest_offers, :ask
  end

  def down
    add_column :order_digest_offers, :ask, :integer
  end
end
