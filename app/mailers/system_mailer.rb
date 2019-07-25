class SystemMailer < BaseMailer
  require 'mailgun'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'action_view'
  include ActionView::Helpers::AssetTagHelper

  def balance_warning(amount, balance)
    @amount  = amount
    @balance = balance
    @ips     = ips
    client_details={}

    client_details[:title] = "Balance warning"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}: Balance warning"
    client_details[:text] = " Source:#{@ips.inspect}  System Balance: #{@balance}  Withdraw Amount: #{@amount}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
       send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def notification_error(payload, error, backtrace)
    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Notification error"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}: Notification error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect}  Payload: #{@payload.inspect} Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def samurai_persistence_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Samurai persistence error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Samurai persistence error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect} Payload: #{@payload.inspect} Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end

  end

  def samurai_status_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Samurai status error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Samurai status error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect} Payload: #{@payload.inspect}  Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def deposit_slip_status_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Deposit Slip status error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Deposit Slip status error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect} Payload: #{@payload.inspect}  Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end

  end

  def samurai_status_change(deposit)
    @deposit   = deposit
    @ips       = ips

    client_details={}
    client_details[:title] = "Samurai status change:"
    client_details[:pretext] ="#{ENV['SERVER_TYPE']}:Samurai status change: #{@deposit.aasm_state}"
    client_details[:text] = "Member e-mail:#{ @deposit.member.email}
        Transaction ID: #{@deposit.txid}
        Amount: #{Currency.find_by_code(@deposit.currency)}  #{@deposit.amount}
        Created at: #{@deposit.created_at}
        Updated at: #{@deposit.updated_at}
        Status:  #{@deposit.aasm_state}
        Source:  #{@ips.inspect}"

    client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    message = Mailgun::MessageBuilder.new

    message.add_recipient  :to, ENV['OPERATE_MAIL_TO']
    message.add_recipient  :from, ENV["MAILGUN_FROM"]
    message.subject        "#{ENV['SERVER_TYPE']}:Samurai status change: #{@deposit.aasm_state}"
    message.body_html "<html><body>
     Member e-mail:#{ @deposit.member.email}
     Transaction ID: #{@deposit.txid}
     Amount: #{Currency.find_by_code(@deposit.currency)}  #{@deposit.amount}
     Created at: #{@deposit.created_at}
     Updated at: #{@deposit.updated_at}
     Status:  #{@deposit.aasm_state}
     Source:  #{@ips.inspect}
    </body></html>"


    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
        client.send_message ENV['SMTP_DOMAIN'], message
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def withdraw_status_change(withdraw)

    time_updated = @withdraw.updated_at
    time_create = @withdraw.created_at

    @withdraw   = withdraw
    @ips       = ips

    client_details={}
    client_details[:title] = "Withdraw status change:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Withdraw status change: #{@withdraw.aasm_state}",
    client_details[:text] ="One WithDraw has been:  #{@withdraw.currency.upcase} was requested
                            Amount: #{Currency.find_by_code(@withdraw.currency).symbol}  #{@withdraw.amount}
                            Create at: #{time_create.strftime('%H:%M')} in day: #{time_create.strftime('%d/%m/Y')}
                            Updated at :  #{time_updated.strftime('%H:%M')} in day: #{time_updated.strftime('%d/%m/Y')}
                            Status : #{ @withdraw.aasm_state}
                            IP Address :  #{@ips.inspect}"

    client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    message = Mailgun::MessageBuilder.new

    message.add_recipient  :to, ENV['OPERATE_MAIL_TO']
    message.add_recipient  :from, ENV["MAILGUN_FROM"]
    message.subject        "#{ENV['SERVER_TYPE']}:Samurai status change: #{@deposit.aasm_state}"
    message.body_html "<html><body>
     One WithDraw has been:  #{@withdraw.currency.upcase} was requested
     Amount: #{Currency.find_by_code(@withdraw.currency).symbol}  #{@withdraw.amount}
     Create at: #{time_create.strftime('%H:%M')} in day: #{time_create.strftime('%d/%m/Y')}
     Updated at :  #{time_updated.strftime('%H:%M')} in day: #{time_updated.strftime('%d/%m/Y')}
     Status : #{ @withdraw.aasm_state}
     IP Address :  #{@ips.inspect}
    </body></html>"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
        client.send_message ENV['SMTP_DOMAIN'], message
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def wallet_mapping_error(payload, error, backtrace)
    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Wallet mapping error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Wallet mapping error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect} Payload: #{@payload.inspect}  Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end

  end

  def address_generator_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Address generator error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}: Address generator error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect} Payload: #{@payload.inspect}  Exception: #{@error} Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def stratum_balance_none(currency)

    @currency  = currency
    @ips       = ips

    client_details={}
    client_details[:title] = "Stratum balance none:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Stratum balance none: #{currency.code}"
    client_details[:text] = " Source: :#{@ips.inspect}  Currency.code: #{@currency.code}  currency.detail: #{ @currency.inspect}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def stratum_withdraw_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Stratum withdraw not found:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Stratum withdraw not found: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect}  Payload: #{@payload.inspect} Exception: #{@error}  Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        puts "Fail send Notifications stratum_withdraw_error"
        #send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end

  end

  def stratum_operation_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Stratum operation error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Stratum operation error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect}  Payload: #{@payload.inspect} Exception: #{@error}  Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end

  def trade_execute_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Trade execute error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Trade execute error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect}  Payload: #{@payload.inspect} Exception: #{@error}  Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end

  end

  def order_processor_error(payload, error, backtrace)

    @payload   = payload
    @error     = error
    @backtrace = backtrace
    @ips       = ips

    client_details={}
    client_details[:title] = "Order processor error:"
    client_details[:pretext] = "#{ENV['SERVER_TYPE']}:Order processor error: #{@error}"
    client_details[:text] = "Source: #{@ips.inspect}  Payload: #{@payload.inspect} Exception: #{@error}  Backtrace: #{@backtrace}"

    begin
      if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
        send_notification_api(client_details)
      end
    rescue
      puts "Fail send Notifications"
    end


  end



  def send_notification_api(client_details)
    require 'nokogiri'
    data = {}

    data[:level] = 'warn'
    data[:channels] = ['slack','telegram']
    data[:app] = 'System Communication'
    data[:realm] = ENV['SERVER_TYPE']
    data[:message] = client_details
    data

    result = RestClient.post(
        ENV['NOTIFICATIONS_API'],
        data.as_json,
        {
            content_type: 'application/json',
            Authorization: ENV['NOTIFICATIONS_API_PWD64']

        }
    )

    rescue Exception => exception
      return result.inspect, exception.message

  end



  def daily_stats(ts, stats, base)
    @stats = stats
    @base  = base

    @changes = {
        assets: Currency.all.map {|c|
          [ c,
            compare(@base['asset_stats'][c.code][1], @stats['asset_stats'][c.code][1]),
            compare(@base['asset_stats'][c.code][0], @stats['asset_stats'][c.code][0])
          ]
        },
        trades: Market.all.map {|m|
          [ m,
            compare(@base['trade_users'][m.id][1], @stats['trade_users'][m.id][1])
          ]
        }
    }

    from   = Time.at(ts)
    to     = Time.at(ts + 1.day - 1)
    #unless ENV['SERVER_TYPE'] != 'live'
      mail subject: "Daily Summary (#{from} - #{to})",
           to: ENV['OPERATE_MAIL_TO']
    #end
  end

  private

  def compare(before, now)
    if before.nil? || now.nil?
      []
    else
      [ now-before, percentage_compare(before, now) ]
    end
  end

  def percentage_compare(before, now)
    if before == 0
      nil
    else
      (now-before) / before.to_f
    end
  end

  def ips
    require 'socket'
    ips_list = []
    addr_infos = Socket.ip_address_list
    addr_infos.each do |addr_info|
      ips_list << addr_info.ip_address
    end
    ips_list
  rescue
    puts "Failed to load ips: #{$!}"
    puts $!.backtrace.join("\n")
    []
  end



end
