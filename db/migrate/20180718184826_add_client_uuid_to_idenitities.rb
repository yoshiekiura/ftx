class AddClientUuidToIdenitities < ActiveRecord::Migration
  def self.up
    add_column :identities, :client_uuid, :string
  end

  def self.down
    remove_column :identities, :client_uuid
  end
  
end
