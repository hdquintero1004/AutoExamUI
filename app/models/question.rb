class Question < ApplicationRecord
  belongs_to :signature
  has_many :options, :dependent => :destroy

  validates :body, :presence => true
  validates :signature_id, :presence => true

end
