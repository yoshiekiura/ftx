class CommentMailer < BaseMailer

  def user_notification(comment_id)
    comment = Comment.find comment_id
    @ticket_url = ticket_url(comment.ticket)
    @client_uuid = client_uuid(comment)

    mail to: comment.ticket.author.email
  end

  def admin_notification(comment_id)
    comment = Comment.find comment_id
    @ticket_url = admin_ticket_url(comment.ticket)
    @author_email = comment.author.email
    @client_uuid = client_uuid(comment)

    mail to: ENV['SUPPORT_MAIL']
  end

  private

  def client_uuid(comment)
    unless comment.is_a?(String) or comment.author.nil? or comment.author.identity.nil?
      comment.author.identity.client_uuid
    end
  end

end
