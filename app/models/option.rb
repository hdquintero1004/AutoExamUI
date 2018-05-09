class Option < ApplicationRecord
  belongs_to :question

  validates :body, :presence => true
  validates :true_or_false, :numericality => true, :inclusion => {:in => 0..1}, :presence => true
end
