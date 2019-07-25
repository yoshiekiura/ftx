class FixMarketId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE trades SET currency = currency - 1")
    ActiveRecord::Base.connection.execute("UPDATE orders SET currency = currency - 1")
  end
  
  def self.down
    ActiveRecord::Base.connection.execute("UPDATE trades SET currency = currency + 1")
    ActiveRecord::Base.connection.execute("UPDATE orders SET currency = currency + 1")
  end 
  
end
