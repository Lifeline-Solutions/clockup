class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@clockup.local'
  layout 'mailer'
end
