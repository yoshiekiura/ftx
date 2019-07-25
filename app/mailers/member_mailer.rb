class MemberMailer < BaseMailer
  require 'mailgun'
  require 'action_view'
  include ActionView::Helpers::AssetTagHelper



  def notify_signin(member_id)

    @member = Member.find member_id
    client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])

    unless member_id.is_a?(String) or  @member.is_a?(String) or   @member.identity.nil?
      @client_uuid = @member.identity.client_uuid

      sign_up_data = SignupHistory.where(member_id: member_id).order(created_at: :desc).limit(4).pluck(:ip, :created_at)
      sign_up_data2 = SignupHistory.where(member_id: member_id).order(created_at: :desc).limit(4)
      @sign_up_data = sign_up_data
      @sign_up_data2 = sign_up_data2


      member = @sign_up_data2.first
      user_agent = UserAgent.parse(member.ua)
      week_day = Date.today.wday


      @msg_format = ""
      @sign_up_data.each do |members|
        @msg_format += "<span style='color:#9A9A9A; font-size: 15px; font-weight: 500'>#{I18n.t('member_mailer.notify_signin.address') + ": &nbsp;" + members[0]}&nbsp;&nbsp;&nbsp; </span>
        <span style='color:#9A9A9A; font-size: 15px; font-weight: 500'>#{I18n.t('member_mailer.notify_signin.date') + ": &nbsp;" + members[1].strftime('%d/%m/%Y')}&nbsp;&nbsp;&nbsp; </span>
        <span style='color:#9A9A9A; font-size: 15px; font-weight: 500'>#{I18n.t('member_mailer.notify_signin.time') + ": &nbsp;" + members[1].strftime('%H:%M')}&nbsp;&nbsp;&nbsp; </span><br>"

      end

      if ENV['MAILGUN_SEND_MEMBER'] =='Y'
        message = Mailgun::MessageBuilder.new

        message.add_recipient :to, @member.email
        message.add_recipient :from, ENV["MAILGUN_FROM"]
        message.subject I18n.t('member_mailer.notify_signin.subject')
        message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
        message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))

        message.body_html "<html>
      <body>

      <head>
      </head>

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
                      <td style='padding-top:5px'>
                      <img src='cid:logo_cx_email.png' >
                       </td>
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
                       <p style='color:#078ABA; font-size:15px;'>
                    #{  I18n.t('mailer.client_uuid')} #{@client_uuid}
                </p>

            <p style='color:#078ABA; font-size:30px; font-weight: 500'>
              #{I18n.t('member_mailer.notify_signin.just_signed_in')}
            </p>
              <p style='font-size:17px'>
              <span style='color:#5F5F5F; font-weight: 500'>
                  #{I18n.t('member_mailer.notify_signin.date')}
                          #{  member.created_at.strftime('%d/%m/%Y') },  #{I18n.t('date.formats.day_names')[week_day]}
              </span>
            <br/>
            <span style='color:#5F5F5F; font-weight: 500'>
                #{I18n.t('member_mailer.notify_signin.time')}
                          #{member.created_at.strftime('%H:%M')}
            </span>
            <br/>

            <span style='color:#5F5F5F; font-weight: bold'>
               #{I18n.t('member_mailer.notify_signin.address')}
                          #{ member.ip}
             </span>
            <br/>
            <span style='color:#5F5F5F; font-weight: 500'>
                  #{I18n.t('member_mailer.notify_signin.browser')}
                          #{ user_agent.browser }
            </span>

            <br/>
            <br/>
            <br/>
             <span style='color:#5F5F5F; font-weight: 500'>#{I18n.t('member_mailer.notify_signin.last')}</span> <br/>
              #{ @msg_format }
            <br/>
            </p>

                        <p style='color:#5F5F5F; font-weight: 500'>#{  I18n.t('mailer.warning') }</p>
                        <p style='color:#5F5F5F; font-weight: 500'>#{  I18n.t('mailer.signature') }</p>
                      </td>
                    </tr>
                    </tbody>
                  </table>
                  <!--body-->
                </td>
              </tr>
              </tbody>
              <tfoot>
                <tr width='100%' style='background:#28363D;' align='center'>
                  <td style='padding-top:5px'>

                   <img src='cid:xlabs_logo_gray.png' >

                  </td>
                </tr>
              </tfoot>
            </table>
          </td>
        </tr>
        </tbody>
      </table>

      </body></html>"


        client.send_message ENV['SMTP_DOMAIN'], message
        mg_events = Mailgun::Events.new(client, ENV['SMTP_DOMAIN'])

        result = mg_events.get({'limit' => 100, 'recipient' => @member.email})

        result.to_h['items'].each do |item|
          Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
        end
      end#fim

    end
  end

  def google_auth_deactivated(member_id)
    @member = Member.find member_id

    unless member_id.is_a?(String) or  @member.is_a?(String) or  @member.identity.nil?
      if ENV['MAILGUN_SEND_MEMBER'] == 'Y'
        @client_uuid = @member.identity.client_uuid
        message = Mailgun::MessageBuilder.new
        client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])

        message.add_recipient :to, @member.email
        message.add_recipient :from, ENV["MAILGUN_FROM"]
        message.subject I18n.t('member_mailer.google_auth_deactivated.subject')
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
         <p style='color:#078ABA; font-size:15px; margin-top:-25px;>
               #{  I18n.t('mailer.client_uuid') + ": &nbsp;" + @client_uuid}
            </p>
            <p style='margin-top:50px; margin-bottom:180px;'>
              <span style='color:#078aba;font-size:30px;font-weight: 500;'>
                 #{t('member_mailer.google_auth_deactivated.google_auth_deactivated')} </span><br/>
                <span style='color:#5F5F5F; font-weight: 500'>
                 #{I18n.t('member_mailer.google_auth_deactivated.tip')}
            </span>
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
        mg_events = Mailgun::Events.new(client, ENV['SMTP_DOMAIN'])

        result = mg_events.get({'limit' => 100, 'recipient' => @member.email})

        result.to_h['items'].each do |item|
          Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
        end
      end
    end
  end

  def google_auth_activated(member_id)
    @member = Member.find member_id

    unless member_id.is_a?(String) or @member.is_a?(String) or   @member.identity.nil?
      if ENV['MAILGUN_SEND_MEMBER'] == 'Y'
        @client_uuid = @member.identity.client_uuid
        message = Mailgun::MessageBuilder.new
        client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
        message.add_recipient :to, @member.email
        message.add_recipient :from, ENV["MAILGUN_FROM"]
        message.subject I18n.t('member_mailer.google_auth_activated.subject')
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
           #{I18n.t('mailer.client_uuid') + ": &nbsp;" + @client_uuid}
      </p>
      <p style='color:#078aba;font-size:30px; line-height: 100%; margin-top:100px; margin-bottom:150px;'>
         #{I18n.t('mailer.congratulation')}<br/>
         #{I18n.t('member_mailer.google_auth_activated.google_auth_activated')}
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
        mg_events = Mailgun::Events.new(client, ENV['SMTP_DOMAIN'])

        result = mg_events.get({'limit' => 100, 'recipient' => @member.email})

        result.to_h['items'].each do |item|
          Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
        end
      end

    end

  end


  def reset_password_done(member_id)
    @member = Member.find member_id
    unless member_id.is_a?(String) or  @member.is_a?(String) or   @member.identity.nil?
      if ENV['MAILGUN_SEND_MEMBER'] == 'Y'
        message = Mailgun::MessageBuilder.new
        client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
        @client_uuid = @member.identity.client_uuid
        message.add_recipient :to, @member.email
        message.add_recipient :from, ENV["MAILGUN_FROM"]
        message.subject I18n.t('member_mailer.reset_password_done.subject')
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
             #{ I18n.t('mailer.client_uuid') + ": &nbsp;" + @client_uuid}
        </p>
        <p style='font-size:40px; line-height: 100%; margin-bottom:200px;margin-top:80px;'>
          <span style='color:#078aba;'>
          #{ t('member_mailer.reset_password_done.congratulations')}</span><br/>
           <span style=1color:#078aba;1>
                #{t('member_mailer.reset_password_done.successful')}
          </span>
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
          mg_events = Mailgun::Events.new(client, ENV['SMTP_DOMAIN'])

          result = mg_events.get({'limit' => 100, 'recipient' => @member.email})

          result.to_h['items'].each do |item|
            Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
          end
        end

    end
  end


end
