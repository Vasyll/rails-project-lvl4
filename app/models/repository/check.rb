# frozen_string_literal: true

class Repository::Check < ApplicationRecord
  include AASM

  aasm whiny_transitions: false do
    state :starting, initial: true
    state :checking
    state :finished
    state :failed

    event :start do
      transitions from: :starting, to: :checking
    end

    event :finish do
      transitions from: :checking, to: :finished
    end

    event :fail do
      transitions from: :checking, to: :failed
    end
  end

  belongs_to :repository
end
