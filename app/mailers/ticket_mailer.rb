class TicketMailer < BaseMailer

  def author_notification(ticket_id)
    ticket = Ticket.find ticket_id
    @ticket_url = ticket_url(ticket)
    @client_uuid = client_uuid(ticket)

    mail to: ticket.author.email
  end

  def admin_notification(ticket_id)
    ticket = Ticket.find ticket_id
    @author_email = ticket.author.email
    @ticket_url = admin_ticket_url(ticket)
    @client_uuid = client_uuid(ticket)

    mail to: ENV['SUPPORT_MAIL']
  end

  private

  def client_uuid(ticket)
    unless ticket.is_a?(String) or ticket.author.nil? or ticket.author.identity.nil?
      ticket.author.identity.client_uuid
    end
  end

end
