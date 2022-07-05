# frozen_string_literal: true

class Web::Repositories::ChecksController < Web::Repositories::ApplicationController
  def create
    check = Repository::Check.new(permitted_params)

    if check.save
      CheckRepositoryJob.perform_later check.id
      redirect_to repository_path(check.repository_id), notice: 'Check created'
    else
      redirect_to repository_path(check.repository_id), alert: 'failure'
    end
  end

  def show
    @check = Repository::Check.find(params[:id])
  end

  def permitted_params
    params.permit(:repository_id)
  end
end
