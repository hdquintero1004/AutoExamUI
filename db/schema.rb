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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180423154209) do

  create_table "exams", force: :cascade do |t|
    t.string   "title"
    t.string   "header"
    t.text     "description"
    t.text     "students_list"
    t.string   "labels"
    t.integer  "amount"
    t.integer  "signature_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "json_master"
    t.string   "json_master_validation"
    t.string   "json_grader"
    t.index ["signature_id"], name: "index_exams_on_signature_id"
  end

  create_table "options", force: :cascade do |t|
    t.text     "body"
    t.integer  "true_or_false"
    t.integer  "question_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.text     "labels"
    t.integer  "signature_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["signature_id"], name: "index_questions_on_signature_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "signatures", force: :cascade do |t|
    t.string   "name"
    t.text     "labels"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teachers", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "signature_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["signature_id"], name: "index_teachers_on_signature_id"
    t.index ["user_id"], name: "index_teachers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.integer  "role_id"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

end
