class Question < ApplicationRecord
  belongs_to :signature
  has_many :options, :dependent => :destroy

  validates :body, :presence => true
  validates :labels_in_signature?

  def labels_in_signature?
    signature_labels = Signature.find(signature_id).labels
  end
end
