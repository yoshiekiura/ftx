class TokenMailer < BaseMailer
  require 'mailgun'
  require 'action_view'
  include ActionView::Helpers::AssetTagHelper



  def reset_password(email, token)
    @client_uuid = client_uuid(token)
    @token_url = edit_reset_password_url(token)

    if ENV['MAILGUN_SEND_TOKEN'] == 'Y'
      client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      message = Mailgun::MessageBuilder.new

      message.add_recipient  :to, email
      message.add_recipient  :from, ENV["MAILGUN_FROM"]
      message.subject        I18n.t('member_mailer.reset_password_done.subject')
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
    <p style='color:#078aba; font-size: 15px; margin-top: -25px'>
    #{ I18n.t('mailer.client_uuid') + ": &nbsp;" + @client_uuid }
    </p>
					  <p style='color:#078aba; font-size:30px;line-height: 100%'>
						#{ I18n.t('token_mailer.reset_password.requested')}
					  </p>

    <p style='margin-bottom:170px;'>
    <span style='color:#5F5F5F; font-weight: 500'>
    #{I18n.t('token_mailer.reset_password.follow_the_link')}
    </span>
      #{ActionController::Base.helpers.link_to @token_url, @token_url}<br/>

    <span style='color:#9A9A9A; font-weight: 500'>
    #{I18n.t('token_mailer.activation.link_expire')}
    </span>
					  </p>


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

      client.send_message ENV['SMTP_DOMAIN'], message
      mg_events = Mailgun::Events.new(client,  ENV['SMTP_DOMAIN'])

      result = mg_events.get({'limit' => 100, 'recipient' => email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end

    end

  end


  def activation(email, token)
    @client_uuid = client_uuid(token)
    @token_url = edit_activation_url(token)

    if ENV['MAILGUN_SEND_TOKEN'] == 'Y'
      client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      message = Mailgun::MessageBuilder.new

      message.add_recipient  :to, email
      message.add_recipient  :from, ENV["MAILGUN_FROM"]
      message.subject        I18n.t('token_mailer.activation.subject')
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
    <td style='padding-top:5px'><img src='cid:logo_cx_email.png' ></td>
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
     <span style='color:#078ABA; font-size:30px; line-height: 100%; font-weight: 500'>
        #{I18n.t('token_mailer.activation.click_to_verify')}
        </span>
        <br/>
        <br/>
        <p>
        <span style='' color:#5F5F5F; font-weight: 500'>
         #{I18n.t('token_mailer.activation.info')}
        </span><br/><br/>
        <span style='margin-top:-25px; color:#078ABA; font-size:34px; font-weight: 500'>
          #{I18n.t('mailer.client_uuid')+"&nbsp;"+ @client_uuid}</span>
        </p>
        <p style='margin-top: 40px'>
        <b>#{I18n.t('token_mailer.activation.validate1')}</b> <br/>
         #{ActionController::Base.helpers.link_to @token_url, @token_url}<br/>
        </p>
        <p style='font-size:12px; font-weight:500; color:#5F5F5F;'>
          #{I18n.t('token_mailer.activation.unable_to_click')}
        <br/>
         #{I18n.t('token_mailer.activation.link_expire')}
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

      client.send_message ENV['SMTP_DOMAIN'], message
      mg_events = Mailgun::Events.new(client,  ENV['SMTP_DOMAIN'])

      result = mg_events.get({'limit' => 100, 'recipient' => email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end
    end

  end

  def remember_id(email, client_uuid)
    @client_uuid = client_uuid
    @token_url = signin_url
    if ENV['MAILGUN_SEND_TOKEN'] == 'Y'
      client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      message = Mailgun::MessageBuilder.new

      message.add_recipient  :to, email
      message.add_recipient  :from, ENV["MAILGUN_FROM"]
      message.subject        I18n.t('token_mailer.activation.subject')
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
         #{ I18n.t('mailer.client_uuid')  +"&nbsp;"+ @client_uuid}
        </p>
        <p style='color:#078aba;font-size:30px; line-height: 100%; margin-top:25px; font-weight: 500'>
           #{I18n.t('mailer.request_id')}
        </p>
        <p style='color:#078ABA; font-size:30px; font-weight: 500'>
         #{I18n.t('mailer.client_uuid') +"&nbsp;"+ @client_uuid}
        </p>

        <p style='margin-bottom:90px; font-weight: 500; color:#5F5F5F;'>
             #{I18n.t('mailer.acess_plataform')}<br/>
             #{ActionController::Base.helpers.link_to @token_url, @token_url}
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

      client.send_message ENV['SMTP_DOMAIN'], message
      mg_events = Mailgun::Events.new(client,  ENV['SMTP_DOMAIN'])

      result = mg_events.get({'limit' => 100, 'recipient' => email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end
    end

  end

  private

  def client_uuid(token)
    _token = Token.find_by_token(token)
    unless _token.nil? or _token.member.nil? or _token.member.identity.nil?
      _token.member.identity.client_uuid
    end
  end

end
