class UserMailerPreview < ActionMailer::Preview
  def invite_user
    user = User.first || User.new(email: 'preview@example.com', organisation: Organisation.first)
    UserMailer.invite_user(user, temp_password: 'Temp1234!')
  end
end
