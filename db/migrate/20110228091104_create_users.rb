class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :uid
      t.string :gender
      t.integer :win
      t.integer :loss
      t.decimal :score

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
