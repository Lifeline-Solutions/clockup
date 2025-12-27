class UserMailer < ApplicationMailer
  def invite_user(user, temp_password: nil)
    @user = user
    @organisation = user.organisation
    @temp_password = temp_password
    mail(to: @user.email, subject: 'Your Clockup account')
  end
end
