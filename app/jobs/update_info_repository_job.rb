# frozen_string_literal: true

class UpdateInfoRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repo_id, token)
    repository = Repository.find(repo_id)
    client = Octokit::Client.new access_token: token, per_page: 100
    repos = client.repos
    repos.each do |repo|
      next if repo[:id] != repository.github_id

      repository.full_name = repo[:full_name]
      repository.language = repo[:language].downcase
      repository.link = repo[:html_url]
      repository.name = repo[:name]
      repository.clone_url = repo[:clone_url]
      puts repo.inspect
      puts "================= #{repo[:clone_url]}"
      puts "================= #{repository.clone_url}"
    end
    #repository.save
    puts "UpdateInfo #{repository.inspect}"
    if repository.save
      puts "UpdateInfo OK"
      rep = Repository.find(repo_id)
      puts "================= #{rep.clone_url}"
    else
      puts "UpdateInfo Fail"
    end 
  end
end
