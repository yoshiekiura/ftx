class RevokeAPITokens < ActiveRecord::Migration
  def self.up
    APIToken.update_all(deleted_at: Time.now)
    APIToken.update_all(expire_at: Time.now)
  end
  
  def self.down
  end 
  
end
