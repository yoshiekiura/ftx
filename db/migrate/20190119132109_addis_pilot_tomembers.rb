class AddisPilotTomembers < ActiveRecord::Migration
  def change
    add_column :members, :is_pilot, :boolean, default: false
  end
end
