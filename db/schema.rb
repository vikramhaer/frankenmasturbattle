# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110308061047) do

  create_table "betas", :force => true do |t|
    t.string   "email"
    t.string   "uid"
    t.boolean  "access",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.string   "gid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "uid"
    t.string   "gender"
    t.integer  "login_count",  :default => 0
    t.integer  "rating_count", :default => 0
    t.integer  "win",          :default => 0
    t.integer  "loss",         :default => 0
    t.decimal  "score",        :default => 1000.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
  end

end
