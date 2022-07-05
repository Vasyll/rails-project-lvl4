# frozen_string_literal: true

class Web::RepositoriesController < ApplicationController
  def index
    @repositories = Repository.where(user_id: current_user.id)
  end

  def show
    @repository = Repository.find(params[:id])
    @checks = @repository.checks.all.order(created_at: :desc)
  end

  def new
    @repository = Repository.new

    @repo_names = []
    client = Octokit::Client.new access_token: current_user.token, per_page: 100
    repos = client.repos
    repos.each do |repo|
      @repo_names << [repo[:full_name], repo[:id]] if Repository.language.values.include?(repo[:language]&.downcase)
    end
  end

  def create
    repository = current_user.repositories.build permitted_params

    if repository.save
      UpdateInfoRepositoryJob.perform_later repository.id, current_user.token
      redirect_to repositories_path, notice: t('.success')
    else
      render :new, alert: t('.failure')
    end
  end

  private

  def permitted_params
    params.require(:repository).permit(:github_id)
  end
end
