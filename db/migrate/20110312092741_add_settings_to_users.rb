class AddSettingsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :settings, :integer, :default => 51360
  end

  def self.down
    remove_column :users, :settings
  end
end
