class Question < ApplicationRecord
  belongs_to :signature
  has_many :options, :dependent => :destroy
end
