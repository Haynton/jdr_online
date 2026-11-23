require "net/smtp"

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.x.mail_sender
  layout "mailer"

  # What an email that cannot leave raises: the SMTP service refuses (wrong login, unknown address of the server,
  # busy), cannot be reached, or does not answer in time. Rescued where an email is sent, to tell the player clearly
  DELIVERY_ERRORS = [
    Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPFatalError, Net::SMTPSyntaxError,
    Net::SMTPUnknownError, Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, SystemCallError,
    OpenSSL::SSL::SSLError
  ].freeze
end
