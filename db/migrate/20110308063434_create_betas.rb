class CreateBetas < ActiveRecord::Migration
  def self.up
    create_table :betas do |t|
      t.string :email
      t.string :uid
      t.boolean :access, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :betas
  end
end
