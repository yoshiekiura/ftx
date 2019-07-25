class DepositMailer < BaseMailer
  require 'mailgun'
  require 'action_view'
  include ActionView::Helpers::AssetTagHelper


  def accepted(deposit_id)
    @deposit = Deposit.find deposit_id

    unless deposit_id.is_a?(String) or
        @deposit.is_a?(String) or
        @deposit.member.nil? or
        @deposit.member.identity.nil?

      @client_uuid = @deposit.member.identity.client_uuid
    end
    time = @deposit.created_at
    unless @deposit.currency_text != 'BRL'

      @fund_source = FundSource.find_by_uid(@deposit.fund_uid)

      conta = @fund_source.uid.split("/")
      bank = @fund_source.label
    else
      @deposit.amount = @deposit.amount.floor(2)
    end
    if ENV['MAILGUN_SEND_DEPOSIT'] == 'Y'
      message = Mailgun::MessageBuilder.new

      message.add_recipient :to, @deposit.member.email
      message.add_recipient :from, ENV["MAILGUN_FROM"]
      message.subject I18n.t('deposit_mailer.accepted.subject')
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
                        <p style='color:#078ABA; font-size:15px;'>
                    #{  I18n.t('mailer.client_uuid')} #{@client_uuid}
                </p>
          <!--body start-->
            <p style='color:#078ABA; font-size:30px;'>
                             #{I18n.t('deposit_mailer.accepted.available')}
                           </p>
                           <p style='color:#5F5F5F; font-weight: 500'>
                             #{I18n.t('deposit_mailer.accepted.accepted', id: @deposit.id) }
                          </p>
                          <p style='color:#078aba;font-size:20px; font-weight: 500'>
                              #{I18n.t('deposit_mailer.accepted.amount', symbol: @deposit.currency_obj.symbol, amount:  @deposit.amount) }
                          </p>
                          <br/>
                          <p style='color:#9A9A9A; font-weight: 500' >
                          #{unless @deposit.currency_text == 'BRL'
                             I18n.t('deposit_mailer.accepted.amount')
                             "&nbsp;"
                             @deposit.fund_uid
                            end}
                           </p>
                           #{unless @deposit.currency_text != 'BRL'
                                                           I18n.t('deposit_mailer.accepted.bank') +
                                                           "&nbsp;" +
                                                           bank + "<br/>" +
                                                           I18n.t('deposit_mailer.accepted.agency') +
                                                           "&nbsp;" +
                                                           conta[1] +
                                                           "<br/>" +
                                                           I18n.t('deposit_mailer.accepted.account') +
                                                           "&nbsp;" +
                                                           conta[2] +
                                                           "<br/>"

                             end}

                          <p style='color:#5F5F5F; font-weight: 500'>
                             #{I18n.t('member_mailer.notify_signin.date') + "&nbsp;" + time.strftime('%d/%m/%Y')} <br/>
                              #{I18n.t('member_mailer.notify_signin.time') + "&nbsp;" + time.strftime('%H:%M')} </p>
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

      result = mg_events.get({'limit' => 100, 'recipient' => @deposit.member.email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end
    end
  end

  def created(deposit_id, samurai_code, expire, type, amount)
    @deposit = Deposit.find deposit_id
    @samurai_code = samurai_code
    expire = expire + 2
    @expire = Time.parse(expire.to_s).strftime("%-d/%-m/%Y %R")
    @type = type


    if @deposit.currency_text == 'BRL'

      @amount = amount.floor(2)
    end


    time = @deposit.created_at
    @date_create = time.strftime('%d/%m/%Y')
    @time_created =time.strftime('%H:%M')
    
    case type
    when "TEF"
      @type_transfer_description = "#{I18n.t('deposit_mailer.accepted.tef')}"
    when "TED"
      @type_transfer_description = "#{I18n.t('deposit_mailer.accepted.ted')}"
    when "DIA"
      @type_transfer_description = "#{I18n.t('deposit_mailer.accepted.dia')}"
      @type = "TEF"
    end

    unless deposit_id.is_a?(String) or
        @deposit.is_a?(String) or
        @deposit.member.nil? or
        @deposit.member.identity.nil?

      @client_uuid = @deposit.member.identity.client_uuid
    end

    if ENV['MAILGUN_SEND_DEPOSIT'] == 'Y'
      message = Mailgun::MessageBuilder.new

      message.add_recipient :to, @deposit.member.email
      message.add_recipient :from, ENV["MAILGUN_FROM"]
      message.subject I18n.t('deposit_mailer.created.subject')
      message.add_inline_image  File.new(File.join("public", "logo_cx_email.png"))
      message.add_inline_image  File.new(File.join("public", "xlabs_logo_gray.png"))
      message.add_inline_image  File.new(File.join("public", "attention_icon.png"))
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
        <td style='padding-top:5px'>  <img src='cid:logo_cx_email.png' ></td>
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
                       <p style='color:#078ABA;'>
                      #{I18n.t('mailer.client_uuid')} #{@client_uuid}
                    </p>

        <!--body start-->
        <p> 
                        <p style='color:#078ABA;font-size:25px; font-weight:bold;'>
                          #{I18n.t('deposit_mailer.created.content_header', type_transfer_description: @type_transfer_description).strip.html_safe} <br/>
                        </p>
                        <label style='font-weight: 400; line-height: normal; margin-right: 80px;'>
                               #{I18n.t('deposit_mailer.created.content_' + @type.downcase , samurai_code: @samurai_code, valor_deposito: @amount, expire: @expire ,date_create: @date_create, time_created: @time_created).strip.html_safe}<br/>
                                #{I18n.t('deposit_mailer.created.content_footer_' + @type.downcase).strip.html_safe }<br/>
                                  </p>
                                <p>
                                #{ I18n.t('mailer.please_contact', contact_mail: ENV['SUPPORT_MAIL'])}
                                </p>

                              </label>


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

      result = mg_events.get({'limit' => 100, 'recipient' => @deposit.member.email})

      result.to_h['items'].each do | item |
        Rails.logger.info "MAILGUN LOG EVENT =  #{item['event']} - MAILGUN LOG = #{item['message']['headers']['message-id']}"
      end
    end
  end

end
