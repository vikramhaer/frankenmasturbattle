class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :uid
      t.string :gender
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
