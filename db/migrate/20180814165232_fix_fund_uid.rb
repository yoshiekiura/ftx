class FixFundUid < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE fund_sources SET uid = SUBSTR(uid,1,LENGTH(uid)-1) WHERE uid LIKE '%-' ")
    ActiveRecord::Base.connection.execute("UPDATE fund_sources SET uid = CONCAT(REPLACE( SUBSTR(uid,1,LENGTH(uid) - 3), '-',''), SUBSTR(uid,LENGTH(uid) - 2)) ")
	ActiveRecord::Base.connection.execute("UPDATE fund_sources SET uid = REPLACE( uid, '-','/') WHERE uid LIKE '%-%' ")
  end
  
  def self.down
  end 
  
end
