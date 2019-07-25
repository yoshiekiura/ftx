class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: :csrf_validate_domain

  helper_method :current_user, :is_admin?, :is_financial?, :is_supporter?, :current_market, :gon, :require_captcha, :browser_detect, :mobile_device
  before_action :set_timezone, :set_gon
  after_action :allow_iframe
  after_action :set_csrf_cookie_for_ng
  after_action :set_access_control_headers
  rescue_from CoinRPC::ConnectionRefusedError, with: :coin_rpc_connection_refused


  private
  include TwoFactorHelper

  def require_captcha
    if params['g_recaptcha_response']
      params['g-recaptcha-response'] = params['g_recaptcha_response']
    end

    verify_recaptcha(model:  @obj)
  end

  def currency
    "#{params[:ask]}#{params[:bid]}".to_sym
  end

  def current_market
    @current_market ||= Market.find_by_id(params[:market]) || Market.find_by_id(cookies[:market_id]) || Market.first
  end

  def redirect_back_or_markets_page
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to market_v2_path(current_market)
    end
  end

  def redirect_back_or_settings_page
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to settings_path
    end
  end

  def redirect_back_or_welcome
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to welcome_path
    end
  end

  def redirect_back_or_root
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to root_path
    end
  end

  def current_user
    @current_user ||= Member.current = Member.enabled.where(id: session[:member_id]).first
  end

  def auth_member!
    unless current_user
      set_redirect_to
      redirect_to signin_path, alert: t('activations.new.session_expire')
    end
  end

  def auth_activated!
    redirect_to settings_path, alert: t('private.settings.index.auth-activated') unless current_user.activated?
  end

  def auth_verified!
    id_document_verified = true
    if ENV["KYC_SETTINGS"] == "true"
      id_document_verified = current_user.id_document_verified?
    end
    unless current_user and current_user.id_document and id_document_verified
      redirect_to settings_path, alert: t('private.settings.index.auth-verified')
    end
  end

  def auth_no_initial!
  end

  def auth_anybody!
    redirect_to welcome_path if current_user
  end

  def auth_admin!
    redirect_to main_app.root_path unless is_admin? or is_supporter?
  end

  def is_admin?
    current_user && current_user.admin?
  end

  def is_financial?
    current_user && current_user.financial?
  end

  def is_supporter?
    current_user && current_user.supporter?
  end

  def check_accounts_limit
    member_count = Member.count
    limit_account = Figaro.env.limit_account.to_i

    if member_count >= limit_account && limit_account != -1
      flash[:alert] = t('activerecord.errors.messages.limit_excedent')
      render controller: :identities, action: :new
    end
  end

  def two_factor_activated!
    if not current_user.two_factors.activated?
      redirect_to settings_path, alert: t('two_factors.auth.please_active_two_factor')
    end
  end

  def two_factor_auth_verified?


    return false if not current_user.two_factors.activated?
    return false if two_factor_failed_locked? && !require_captcha


    two_factor = current_user.two_factors.by_type(params[:two_factor][:type])
    return false if not two_factor

    two_factor.assign_attributes params.require(:two_factor).permit(:otp)
    if two_factor.verify?
      clear_two_factor_auth_failed
      true
    else
      increase_two_factor_auth_failed
      false
    end
  end

  def two_factor_failed_locked?
    failed_two_factor_auth > 2
  end

  def failed_two_factor_auth
    Rails.cache.read(failed_two_factor_auth_key) || 0
  end

  def failed_two_factor_auth_key
    "coliseum:session:#{request.ip}:failed_two_factor_auths"
  end

  def increase_two_factor_auth_failed
    Rails.cache.write(failed_two_factor_auth_key, failed_two_factor_auth+1, expires_in: 1.month)
  end

  def clear_two_factor_auth_failed
    Rails.cache.delete failed_two_factor_auth_key
  end

  def set_timezone
    Time.zone = ENV['TIMEZONE'] if ENV['TIMEZONE']
  end

  def set_gon
    gon.env = Rails.env
    gon.local = I18n.locale

    gon.market = current_market.attributes
    gon.ticker = current_market.ticker
    gon.markets = Market.to_hash

    gon.pusher = {
      key:       ENV['PUSHER_KEY']       || '4b19d00291e92519a9cb',
      cluster:   ENV['PUSHER_CLUSTER']   || 'us2',
      encrypted: ENV['PUSHER_ENCRYPTED'] == 'true',
    }

    gon.clipboard = {
      :click => I18n.t('actions.clipboard.click'),
      :done => I18n.t('actions.clipboard.done')
    }

    gon.i18n = {
      brand: I18n.t('gon.brand'),
      ask: I18n.t('gon.ask'),
      bid: I18n.t('gon.bid'),
      cancel: I18n.t('actions.cancel'),
      latest_trade: I18n.t('private.markets.order_book.latest_trade'),
      switch: {
        notification: I18n.t('private.markets.settings.notification'),
        sound: I18n.t('private.markets.settings.sound')
      },
      notification: {
        title: I18n.t('gon.notification.title'),
        enabled: I18n.t('gon.notification.enabled'),
        new_trade: I18n.t('gon.notification.new_trade')
      },
      time: {
        minute: I18n.t('chart.minute'),
        hour: I18n.t('chart.hour'),
        day: I18n.t('chart.day'),
        week: I18n.t('chart.week'),
        month: I18n.t('chart.month'),
        year: I18n.t('chart.year')
      },
      chart: {
        price: I18n.t('chart.price'),
        volume: I18n.t('chart.volume'),
        open: I18n.t('chart.open'),
        high: I18n.t('chart.high'),
        low: I18n.t('chart.low'),
        close: I18n.t('chart.close'),
        candlestick: I18n.t('chart.candlestick'),
        line: I18n.t('chart.line'),
        zoom: I18n.t('chart.zoom'),
        depth: I18n.t('chart.depth'),
        depth_title: I18n.t('chart.depth_title')
      },
      place_order: {
        confirm_submit: I18n.t('private.markets.show.confirm'),
        confirm_cancel: I18n.t('private.markets.show.cancel_confirm'),
        price: I18n.t('private.markets.place_order.price'),
        volume: I18n.t('private.markets.place_order.amount'),
        sum: I18n.t('private.markets.place_order.total'),
        price_high: I18n.t('private.markets.place_order.price_high'),
        price_low: I18n.t('private.markets.place_order.price_low'),
        full_bid: I18n.t('private.markets.place_order.full_bid'),
        full_ask: I18n.t('private.markets.place_order.full_ask')
      },
      trade_state: {
        new: I18n.t('private.markets.trade_state.new'),
        partial: I18n.t('private.markets.trade_state.partial')
      }
    }

    gon.currencies = Currency.all_no_filter.inject({}) do |memo, currency|
      memo[currency.code] = {
        code: currency[:code],
        symbol: currency[:symbol],
        isCoin: currency[:coin],
        maintenance: currency[:maintenance]
      }
      memo
    end

    # Variables for deposits
    gon.fiat_currency = Currency.first.code

    gon.tickers = {}
    Market.all.each do |market|
      #gon.tickers[market.id] = market.unit_info.merge(Global[market.id].ticker)
    end

    gon.slip_system_method = Slip.system_slip_method
    gon.slips = {}
    gon.slips = Slip.all.inject({}) do |memo, slip|
      memo[slip.id] = {
          code: slip[:code].to_s.pluralize,
          name: slip[:name],
          id: slip[:id],
          tax: slip[:tax]
      }
      memo
    end

    gon.fees_withdraws = {}
    Currency.all.each do |currency|
      gon.fees_withdraws[currency.code] = {
          fee: get_fee_withdraw_stratum(currency.code)
      }
    end

    if current_user
      gon.current_user = { sn: current_user.sn }
      gon.current_xpto = { id: current_user.id }
      gon.accounts = current_user.accounts.inject({}) do |memo, account|
        memo[account.currency] = {
          currency: account.currency,
          balance: account.balance,
          locked: account.locked
        } if account.currency_obj.try(:visible)
        memo
      end
    end

    gon.session_expire = ENV['SESSION_EXPIRE']
    gon.deposit_modal_expire = ENV['DEPOSIT_MODAL_EXPIRE']
  end

  def coin_rpc_connection_refused
    render 'errors/connection'
  end

  def save_session_key(member_id, key)
    Rails.cache.write "coliseum:sessions:#{member_id}:#{key}", 1, expire_after: ENV['SESSION_EXPIRE'].to_i.minutes
  end

  def get_fee_withdraw_stratum(currency)
    Rails.cache.read "peatio:hotwallet:#{currency}:withdraw_fee".to_s
  end

  def clear_all_sessions(member_id)
    if redis = Rails.cache.instance_variable_get(:@data)
      redis.keys("coliseum:sessions:#{member_id}:*").each {|k| Rails.cache.delete k.split(':').last }
    end

    Rails.cache.delete_matched "coliseum:sessions:#{member_id}:*"
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options' if Rails.env.development?
  end

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || form_authenticity_token == request.headers['X-XSRF-TOKEN']
  end

  def csrf_validate_domain
    return csrf_skip_domain.include?( env['SERVER_NAME'] ) ||
        csrf_skip_domain.include?( http_origin_domain )
  end

  def csrf_skip_domain
    @csrf_skip_domain || ENV['CSRF_SKIP_DOMAIN'].split(',')
  end

  def set_access_control_headers
    if csrf_validate_domain and !env['HTTP_ORIGIN'].nil?
      headers['Access-Control-Allow-Origin'] = '*'
    end
  end

  def http_origin_domain
    unless env['HTTP_ORIGIN'].nil?
      host = URI.parse( env['HTTP_ORIGIN'] ).host
      host = host.gsub('www.','') unless host.nil?
      return host
    else
      return ''
    end
  end

  private
  def browser_detect
    sign_up_data = SignupHistory.where(member_id: gon.current_xpto[:id]).order(created_at: :desc).pluck(:ua)
    ua =  UserAgent.parse(sign_up_data.first)

    if ua.browser == 'Chrome' or ua.browser == 'Firefox'
      return false;
    elsif !mobile_device
      return true;
    end
  end

  def mobile_device
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end

end
