namespace :hotsite_migration do
  desc "Batch to create users from hotsite dump"
  task sync_users: :environment do
    CSV.foreach("#{Rails.root}/db/hotsite_users.csv") do |row|
      array_row =  Array.new(row.split())
      id = Identity.new()
      id.email= array_row[0][0]
      senha = array_row[0][1]
      if senha.nil?
        senha="huIDHAou894y1878ruqibr7e78biajlbdha"
      end
      id.password=senha
      id.password_confirmation=senha
      id.save

      auth_hash = {
          'provider' => 'identity',
          'uid' => id.id,
          'info' => { 'email' => id.email }
      }
      Member.from_auth(auth_hash)
    end

    CSV.open("#{Rails.root}/db/hotsite_client_id.csv", "wb") do |csv|
      Identity.all().each do |id|
        csv << [id.email, id.client_uuid]
      end
    end
  end
end