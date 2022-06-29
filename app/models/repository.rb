# frozen_string_literal: true

class Repository < ApplicationRecord
  extend Enumerize

  belongs_to :user
  has_many :checks, dependent: :destroy

  enumerize :language, in: %i[javascript ruby]

  validates :github_id, presence: true
end
