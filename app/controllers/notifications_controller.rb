# What waits for an answer from the user: the friend requests received and the invitations to a table.
# Loaded into the window of the bell (shared/_notifications_dialog); opened directly or without JavaScript, a page
class NotificationsController < ApplicationController
  include VariesOnTurboFrame

  def show
    @notifications = Notification.for(current_user)
  end
end
