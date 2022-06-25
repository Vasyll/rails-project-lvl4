# frozen_string_literal: true

class Web::RepositoriesController < ApplicationController
  def index
    @repositories = Repository.where(user_id: current_user.id)
  end

  def show
    @repository = Repository.find(params[:id])
  end

  def new
    @repository = Repository.new

    @repo_names = []
    client = Octokit::Client.new access_token: current_user.token, per_page: 100
    repos = client.repos
    repos.each do |repo|
      @repo_names << repo[:full_name] if Repository.language.values.include?(repo[:language]&.downcase)
    end
  end

  def create; end

  private

  def permitted_params
    params.require(:repository).permit(:link)
  end
end
