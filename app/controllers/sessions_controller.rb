class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :auth_member!, only: [:destroy]
  before_action :auth_anybody!, only: [:new, :failure]
  before_action :add_auth_for_weibo
  helper_method :require_captcha


  def new
     @identity = Identity.new
  end

  def create
    if require_captcha
      if  params[:auth_key].nil?
        @member = Member.from_auth(auth_hash)
      elsif params[:auth_key]
        @member = Member.from_auth(auth_hash)
      else
        redirect_to signup_path, alert: t('sessions.create.accept_terms')
        return
      end

    end

    if @member
      if ENV['SERVER_TYPE'] == 'pilot' and @member.is_pilot?
        if @member.disabled?
          increase_failed_logins
          redirect_to signin_path, alert: t('sessions.failure.account_locked')
        else
          clear_failed_logins
          reset_session rescue nil
          session[:member_id] = @member.id
          save_session_key @member.id, cookies['_cointrade_session']
          save_signup_history @member.id

          begin
            MemberMailer.notify_signin(@member.id) if @member.activated?
          rescue
            puts "Fail send mail"
          end

          redirect_back_or_welcome
        end
      elsif ENV['SERVER_TYPE'] != 'pilot' and !@member.is_pilot?

        if @member.disabled?
          increase_failed_logins
          redirect_to signin_path, alert: t('sessions.failure.account_locked')
        else
          clear_failed_logins
          reset_session rescue nil
          session[:member_id] = @member.id
          save_session_key @member.id, cookies['_cointrade_session']
          save_signup_history @member.id

          begin
            MemberMailer.notify_signin(@member.id) if @member.activated?
          rescue
            puts "Fail send mail"
          end

          redirect_back_or_welcome
        end
      else
        redirect_to signin_path, alert: t('sessions.failure.error_pilot')
        return
      end

    else
      increase_failed_logins
      redirect_to signin_path, alert: t('sessions.create.error')
    end

  end

  def failure
    redirect_to signin_path, alert: t('sessions.failure.error')
  end

  def destroy
    clear_all_sessions current_user.id
    reset_session

    redirect_to ENV['INSTITUTIONAL_HOST']
  end

  private
  def require_captcha
    if ENV['SERVER_TYPE'] != 'live' ||  ENV['SERVER_TYPE'] != 'pilot'
      true
    else
      verify_recaptcha(model:  @member)
    end

  end

  def failed_logins
    Rails.cache.read(failed_login_key) || 0
  end

  def increase_failed_logins
    Rails.cache.write(failed_login_key, failed_logins+1)
  end

  def clear_failed_logins
    Rails.cache.delete failed_login_key
  end

  def failed_login_key
    "peatio:session:#{request.ip}:failed_logins"
  end

  def auth_hash
    @auth_hash ||= env["omniauth.auth"]
  end

  def add_auth_for_weibo
    if current_user && ENV['WEIBO_AUTH'] == "true" && auth_hash.try(:[], :provider) == 'weibo'
      redirect_to settings_path, notice: t('.weibo_bind_success') if current_user.add_auth(auth_hash)
    end
  end

  def save_signup_history(member_id)
    SignupHistory.create(
      member_id: member_id,
      ip: request.ip,
      accept_language: request.headers["Accept-Language"],
      ua: request.headers["User-Agent"]
    )
  end
   # add_method_tracer :save_signup_history
   # add_method_tracer :create
   # add_method_tracer :new
  # add_transaction_tracer :save_signup_history,
  #                        :name => 'save_signup_onde_history',   # Change the label from "process_account" to "process_one_account"
  #                        :category => "OtherTransaction/save" # Put in the background tasks under "Nightly"
  # add_transaction_tracer :create,
  #                        :name => 'create',   # Change the label from "process_account" to "process_one_account"
  #                        :category => "OtherTransaction/create" # Put in the background tasks under "Nightly"
  # add_transaction_tracer :new,
  #                        :name => 'new',   # Change the label from "process_account" to "process_one_account"
  #                        :category => "OtherTransaction/new" # Put in the background tasks under "Nightly"
end
