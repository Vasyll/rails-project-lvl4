# frozen_string_literal: true

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repo_id, token); end
end
