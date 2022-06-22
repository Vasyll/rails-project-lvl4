# frozen_string_literal: true

class Web::AuthController < Web::ApplicationController
  def callback
    email = auth[:info][:email].downcase
    existing_user = User.find_by(email: email)

    if existing_user
      sign_in existing_user
      redirect_to root_path, notice: t('.success')
      return
    end

    user_params = {
      email: auth[:info][:email].downcase,
      image_url: auth[:info][:image],
      name: auth[:info][:name],
      nickname: auth[:info][:nickname],
      token: auth[:credentials][:token]
    }
    user = User.new(user_params)

    if user.save
      sign_in user
      redirect_to root_path, notice: t('.success')
    else
      redirect_to root_path, alert: t('.failure')
    end
  end

  def logout
    sign_out
    redirect_to root_path, notice: t('.success')
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
