class UpdateFundUidBankCode < ActiveRecord::Migration
  def self.up
    banks = { '_237':'bra',
              '_745':'cit',
              '_748':'sicr',
              '_001':'bb',
              '_077':'int',
              '_212':'orig',
              '_033':'sant',
              '_637':'sof',
              '_104':'cef',
              '_341':'ita' }
			   
    banks.each do |code,name|
      puts "Changing #{name} to #{code}"
	  ActiveRecord::Base.connection.execute("UPDATE fund_sources SET extra = '#{code}' WHERE extra = '#{name}';")
	  ActiveRecord::Base.connection.execute("UPDATE deposits SET fund_extra = '#{code}' WHERE fund_extra = '#{name}';")
	  ActiveRecord::Base.connection.execute("UPDATE withdraws SET fund_extra = '#{code}' WHERE fund_extra = '#{name}';")
	  ActiveRecord::Base.connection.execute("UPDATE versions SET object = REPLACE(object, 'fund_extra: #{name}', 'fund_extra: #{code}')")
    end
	
  end
  
  def self.down
  end 
  
end
