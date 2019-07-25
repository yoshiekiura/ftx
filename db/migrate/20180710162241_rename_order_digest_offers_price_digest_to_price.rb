class RenameOrderDigestOffersPriceDigestToPrice < ActiveRecord::Migration
  def change
    rename_column :order_digest_offers, :price_digest, :price
    rename_column :order_digest_offers, :count_number, :volume
    rename_column :order_digest_requests, :price_digest, :price
    rename_column :order_digest_requests, :count_number, :volume
  end
end