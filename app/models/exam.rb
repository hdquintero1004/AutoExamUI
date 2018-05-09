class Exam < ApplicationRecord
  belongs_to :signature

  validates :title, :presence => true
  validates :amount, :numericality => true, :presence => true
end
