class Signature < ApplicationRecord
  has_many :questions
  has_many :users, through: :teachers
end
