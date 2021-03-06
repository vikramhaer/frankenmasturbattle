class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :null => false
      t.string :uid, :unique => "true", :null => false
      t.string :gender
      t.integer :login_count, :default => 0
      t.integer :rating_count, :default => 0
      t.integer :win, :default => 0
      t.integer :loss, :default => 0
      t.decimal :score, :default => 1000

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
