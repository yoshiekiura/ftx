class WithdrawMailer < BaseMailer
  require 'mailgun'
  require 'action_view'
  include ActionView::Helpers::AssetTagHelper



  def submitted(withdraw_id)

    @withdraw = Withdraw.find withdraw_id
    @client_uuid = client_uuid( withdraw_id )
    @fund_source = FundSource.find_by(@withdraw.member.id)
    time = @withdraw.created_at
    week_day = Date.today.wday
    unless @withdraw.currency_text != 'BRL'
      conta = @fund_source.uid.split("/")
      bank = @fund_source.label
      @withdraw.amount = @withdraw.amount.floor(2)

    end
    if ENV['MAILGUN_SEND_WITHDRAW'] == 'Y'
      message = Mailgun::MessageBuilder.new

      message.add_recipient :to,  @withdraw.member.email
      message.add_recipient :from, ENV["MAILGUN_FROM"]
      message.subject I18n.t('withdraw_mailer.submitted.subject')
      message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
      message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))
      message.body_html "<html><body><head></head>

      <table cellspacing='0' cellpadding='0' width='100%' align='center' border='0' style=' background: #EEEEEE; font:14px/20px 'Helvetica', Arial, sans-serif;'>
          <tbody>
      <tr>
      <td style='padding: 30px 0;'><table cellspacing='0' cellpadding='0' width='550' align='center' border='0' style='background: #FFFFFF; border-radius: 10px'>
      <tbody>
      <tr>
      <td>
      <table width='100%' style='background:#28363D;'>
      <tbody>
      <tr align='center'>
      <td style='padding-top:5px'> <img src='cid:logo_cx_email.png' ></td>
      </tr>
       </tbody>
      </table></td>
      </tr>
          <tr>
            <td style='border-top:none; padding:30px; padding-top:0px; color: #666 !important;'>
              <!--body-->
              <table>
                <tbody>
                <tr>
                  <td>
                    <p style='color:#078ABA; font-size:30px; margin-bottom: -12px; font-weight: 500'>#{I18n.t('mailer.dear_user') }
                    </p>
      <!--body start-->
      <p style='color:#078ABA; font-size:15px; margin-top:-25px;'>
          #{I18n.t('mailer.client_uuid') + "&nbsp;" + @client_uuid}
           </p>
           <p style='color:#078ABA; font-size:30px; margin-bottom: -25px; font-weight: 500'>
            #{I18n.t('withdraw_mailer.submitted.request')}
            </p>
            <p style='color:#5F5F5F; font-weight: 500'>
            #{I18n.t('withdraw_mailer.submitted.content', {currency: @withdraw.currency_text, number: @withdraw.id})}
           </p>
         <p style='color:#078aba;font-size:20px; font-weight: 500'>
          #{ unless @withdraw.currency_text == 'BRL'
               I18n.t('withdraw_mailer.done.amount_crypto', {amount:  @withdraw.amount, currency: @withdraw.currency_text}) + "<br/>"
             end }
          </p>
         <p style='color:#078aba;font-size:20px; font-weight: 500'>
         #{ unless @withdraw.currency_text != 'BRL'
                                I18n.t('withdraw_mailer.done.amount', {symbol: @withdraw.currency_obj.symbol, amount:  @withdraw.amount}) + "0<br/>"
            end }
        </p>
       <p style='color:#9A9A9A; font-weight: 500' >
        #{ unless @withdraw.currency_text == 'BRL'

                              I18n.t('withdraw_mailer.submitted.request') + "&nbsp;" + @withdraw.fund_uid
           end } </p>
        <p style='color:#9A9A9A; font-weight: 500'>
        #{ unless @withdraw.currency_text != 'BRL'
                             I18n.t('deposit_mailer.accepted.bank') + "&nbsp;" + bank + "<br/>"
                             I18n.t('deposit_mailer.accepted.agency') + "&nbsp;" + conta[1] + "<br/>"
                             I18n.t('deposit_mailer.accepted.account') + "&nbsp;" +  conta[2] + "<br/>"
           end }</p>

        <p style='color:#5F5F5F; font-weight: 500'>
             #{I18n.t('member_mailer.notify_signin.date') + "&nbsp;" + time.strftime('%d/%m/%Y') + "&nbsp;" + I18n.t('date.formats.day_names')[week_day] } <br/>
             #{I18n.t('member_mailer.notify_signin.time') + "&nbsp;" + time.strftime('%H:%M')} </p>

        </p>
      <br/>
          <br/>


      <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.warning') }</p>
      <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.signature') }</p>
      </td>
                </tr>
      </tbody>
              </table>

      </td>
          </tr>
     </tbody>
      <tfoot>
       <tr width='100%' style='background:#28363D;' align='center'>
              <td style='padding-top:5px'><img src='cid:xlabs_logo_gray.png' ></td>
      </tr>
          </tfoot>
      </table>
      </td>
      </tr>
      </tbody>
      </table>
      </body></html>"
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      mg_client.send_message ENV['SMTP_DOMAIN'], message

      mg_events = Mailgun::Events.new(mg_client,  ENV['SMTP_DOMAIN'])

      result = mg_events.get({'limit' => 100, 'recipient' => @withdraw.member.email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end


    end

  end

  def processing(withdraw_id)

    @withdraw = Withdraw.find withdraw_id
    @client_uuid = client_uuid( withdraw_id )
    @fund_source = FundSource.find_by(@withdraw.member.id)

    if ENV['MAILGUN_SEND_WITHDRAW'] == 'Y'
      message = Mailgun::MessageBuilder.new

      message.add_recipient :to,  @withdraw.member.email
      message.add_recipient :from, ENV["MAILGUN_FROM"]
      message.subject I18n.t('withdraw_mailer.processing.subject')
      message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
      message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))
      message.body_html "<html><body><head></head>

    <table cellspacing='0' cellpadding='0' width='100%' align='center' border='0' style=' background: #EEEEEE; font:14px/20px 'Helvetica', Arial, sans-serif;'>
        <tbody>
    <tr>
    <td style='padding: 30px 0;'><table cellspacing='0' cellpadding='0' width='550' align='center' border='0' style='background: #FFFFFF; border-radius: 10px'>
    <tbody>
    <tr>
    <td>
    <table width='100%' style='background:#28363D;'>
    <tbody>
    <tr align='center'>
    <td style='padding-top:5px'> <img src='cid:logo_cx_email.png' ></td>
    </tr>
     </tbody>
    </table></td>
    </tr>
        <tr>
          <td style='border-top:none; padding:30px; padding-top:0px; color: #666 !important;'>
            <!--body-->
            <table>
              <tbody>
              <tr>
                <td>
                  <p style='color:#078ABA; font-size:30px; margin-bottom: -12px; font-weight: 500'>#{I18n.t('mailer.dear_user') }
                  </p>
    <!--body start-->
	  <p>
                         #{I18n.t('withdraw_mailer.processing.content', currency: @withdraw.currency_text)}
                      </p>
                       <p>

                       #{I18n.t('mailer.please_contact', contact_mail: ENV['SUPPORT_MAIL'])}

                      </p>
        <br/>


    <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.warning') }</p>
    <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.signature') }</p>
    </td>
              </tr>
    </tbody>
            </table>

    </td>
        </tr>
   </tbody>
    <tfoot>
     <tr width='100%' style='background:#28363D;' align='center'>
            <td style='padding-top:5px'><img src='cid:xlabs_logo_gray.png' ></td>
    </tr>
        </tfoot>
    </table>
    </td>
    </tr>
    </tbody>
    </table>
    </body></html>"

      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      mg_client.send_message ENV['SMTP_DOMAIN'], message
      mg_events = Mailgun::Events.new(mg_client,  ENV['SMTP_DOMAIN'])

      result = mg_events.get({'limit' => 100, 'recipient' => @withdraw.member.email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end

    end
  end

  def done(withdraw_id)

    @withdraw = Withdraw.find withdraw_id
    @client_uuid = client_uuid( withdraw_id )
    @fund_source = FundSource.find_by(@withdraw.member.id)
    time = @withdraw.created_at
    conta = @fund_source.uid.split("/")
    bank = @fund_source.label

    if @withdraw.currency_text == 'BRL'
      @withdraw.amount = @withdraw.amount.floor(2)
    end

    message = Mailgun::MessageBuilder.new

    message.add_recipient :to,  @withdraw.member.email
    message.add_recipient :from, ENV["MAILGUN_FROM"]
    message.subject I18n.t('withdraw_mailer.done.subject')
    message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
    message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))
    message.body_html "<html><body><head></head>

    <table cellspacing='0' cellpadding='0' width='100%' align='center' border='0' style=' background: #EEEEEE; font:14px/20px 'Helvetica', Arial, sans-serif;'>
        <tbody>
    <tr>
    <td style='padding: 30px 0;'><table cellspacing='0' cellpadding='0' width='550' align='center' border='0' style='background: #FFFFFF; border-radius: 10px'>
    <tbody>
    <tr>
    <td>
    <table width='100%' style='background:#28363D;'>
    <tbody>
    <tr align='center'>
    <td style='padding-top:5px'> <img src='cid:logo_cx_email.png' ></td>
    </tr>
     </tbody>
    </table></td>
    </tr>
        <tr>
          <td style='border-top:none; padding:30px; padding-top:0px; color: #666 !important;'>
            <!--body-->
            <table>
              <tbody>
              <tr>
                <td>
                  <p style='color:#078ABA; font-size:30px; margin-bottom: -12px; font-weight: 500'>#{I18n.t('mailer.dear_user') }
                  </p>
    <!--body start-->
	    <p style='color:#078ABA; font-size:15px; margin-top:-25px;'>
                       #{ I18n.t('mailer.client_uuid') + "&nbsp;" + @client_uuid }
                        </p>
                        <p style='line-height: 100%;'>
                          <span style='color:#078ABA; font-size:30px; font-weight: 500'>
                             #{I18n.t('withdraw_mailer.done.aproved')}
                           </span>
                            <p style='color:#9A9A9A; font-weight: 500' >
                           #{I18n.t('withdraw_mailer.done.aproved') + "&nbsp;" + @withdraw.txid.to_s unless @withdraw.currency_text == 'BRL'}
                        </p>
                        </p>
                        <p style='color:#5F5F5F; font-weight: 500'>

                            #{I18n.t('.content', currency: @withdraw.currency_text, number: @withdraw.id)}

                        </p>

                      <p style='color:#078aba;font-size:20px; font-weight: 500'>
                          #{I18n.t('withdraw_mailer.done.amount', symbol: @withdraw.currency_obj.symbol, amount:  @withdraw.amount)}
                      </p>
                    <p style='color:#9A9A9A; font-weight: 500' >
                    #{unless @withdraw.currency_text == 'BRL'
                         I18n.t('deposit_mailer.accepted.destiny') + "&nbsp;" + @withdraw.fund_uid + "<br/>"

                      end }
                    </p>
                    #{ unless @withdraw.currency_text != 'BRL'
                                                    I18n.t('deposit_mailer.accepted.bank') + "&nbsp;"+ bank + "<br/>"
                                                    I18n.t('deposit_mailer.accepted.agency') + "&nbsp;"+ conta[1] + "<br/>"
                                                    I18n.t('deposit_mailer.accepted.account') + "&nbsp;"+  conta[2] + "<br/>"
                       end }
                    </p>
                    <p style='color:#5F5F5F; font-weight: 500'>
                          #{I18n.t('member_mailer.notify_signin.date') + "&nbsp;" + time.strftime('%d/%m/%Y')} <br/>
                          #{I18n.t('member_mailer.notify_signin.time') + "&nbsp;" + time.strftime('%H:%M')} </p>
                          </p>
                    <br/>
        <br/>
        <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.warning') }</p>
        <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.signature') }</p>
        </td>
                  </tr>
        </tbody>
                </table>

        </td>
            </tr>
       </tbody>
        <tfoot>
         <tr width='100%' style='background:#28363D;' align='center'>
                <td style='padding-top:5px'><img src='cid:xlabs_logo_gray.png' ></td>
        </tr>
            </tfoot>
        </table>
        </td>
        </tr>
        </tbody>
        </table>
        </body></html>"
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mg_client.send_message ENV['SMTP_DOMAIN'], message
    mg_events = Mailgun::Events.new(mg_client,  ENV['SMTP_DOMAIN'])

    result = mg_events.get({'limit' => 100, 'recipient' => @withdraw.member.email})

    result.to_h['items'].each do | item |
      Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
    end


  end


  def withdraw_state(withdraw_id)

   @withdraw = Withdraw.find withdraw_id
   @client_uuid = client_uuid( withdraw_id )
   @fund_source = FundSource.find_by(@withdraw.member.id)

   if ENV['MAILGUN_SEND_WITHDRAW'] == 'Y'
     message = Mailgun::MessageBuilder.new

     message.add_recipient :to,  @withdraw.member.email
     message.add_recipient :from, ENV["MAILGUN_FROM"]
     message.subject I18n.t('withdraw_mailer.withdraw_state.subject')
     message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
     message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))
     message.body_html"<html><body><head></head>

    <table cellspacing='0' cellpadding='0' width='100%' align='center' border='0' style=' background: #EEEEEE; font:14px/20px 'Helvetica', Arial, sans-serif;'>
        <tbody>
    <tr>
    <td style='padding: 30px 0;'><table cellspacing='0' cellpadding='0' width='550' align='center' border='0' style='background: #FFFFFF; border-radius: 10px'>
    <tbody>
    <tr>
    <td>
    <table width='100%' style='background:#28363D;'>
    <tbody>
    <tr align='center'>
    <td style='padding-top:5px'> <img src='cid:logo_cx_email.png' ></td>
    </tr>
     </tbody>
    </table></td>
    </tr>
        <tr>
          <td style='border-top:none; padding:30px; padding-top:0px; color: #666 !important;'>
            <!--body-->
            <table>
              <tbody>
              <tr>
                <td>
                  <p style='color:#078ABA; font-size:30px; margin-bottom: -12px; font-weight: 500'>#{I18n.t('mailer.dear_user') }
                  </p>
        <!--body start-->
      <p>
                       #{I18n.t('withdraw_mailer.withdraw_state.your_state') + "&nbsp;" + @withdraw.aasm_state }
                   </p>
                   <p>

                   #{I18n.t('mailer.please_contact', contact_mail: ENV['SUPPORT_MAIL'])}

                    </p>
        <br/>
     <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.warning') }</p>
    <p style='color:#5F5F5F; font-weight: 500'>#{ I18n.t('mailer.signature') }</p>
    </td>
              </tr>
    </tbody>
            </table>

    </td>
        </tr>
   </tbody>
    <tfoot>
     <tr width='100%' style='background:#28363D;' align='center'>
            <td style='padding-top:5px'><img src='cid:xlabs_logo_gray.png' ></td>
    </tr>
        </tfoot>
    </table>
    </td>
    </tr>
    </tbody>
    </table>
    </body></html>"
     mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
     mg_client.send_message ENV['SMTP_DOMAIN'], message
     mg_events = Mailgun::Events.new(mg_client,  ENV['SMTP_DOMAIN'])

     result = mg_events.get({'limit' => 100, 'recipient' => @withdraw.member.email})

     result.to_h['items'].each do | item |
       Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
     end


   end


  end

  private

  def client_uuid(withdraw_id)
    client_uuid = nil
    withdraw = Withdraw.find withdraw_id

    unless withdraw_id.is_a?(String) or
        withdraw.is_a?(String) or
        withdraw.member.nil? or
        withdraw.member.identity.nil?

      client_uuid = withdraw.member.identity.client_uuid
    end
    return client_uuid
  end



end
