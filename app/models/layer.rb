class Layer < ActiveRecord::Base
  has_many :tools, dependent: :destroy

  validates :api_id, :name, :slug, presence: true
end