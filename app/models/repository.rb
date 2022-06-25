# frozen_string_literal: true

class Repository < ApplicationRecord
  extend Enumerize

  belongs_to :user

  enumerize :language, in: %i[javascript ruby]
end
