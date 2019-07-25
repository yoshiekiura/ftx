class RemembersController < ApplicationController
  include Concerns::TokenManagement

  before_action :auth_anybody!

  def new
    @token = Token::RememberId.new
  end

  def create
    check_member(remember_client_uuid_params)

    @token = Token::RememberId.new(remember_client_uuid_params)

    if @token.save
      clear_all_sessions @token.member_id
      redirect_to signin_path, notice: t('.success')
    else
      redirect_to url_for(action: :new), alert: @token.errors.full_messages.join(', ')
    end
  end

  private
  def remember_client_uuid_params
    params.required(:remember).permit(:email)
  end

  def check_member(remember_params)
    email = remember_params[:email]
    member = Member.find_by_email(email)

    identity = Identity.find_by_email(email)
    if member.nil? and !identity.nil?
      ActiveRecord::Base.transaction do
        auth_hash = {}
        auth_hash['info'] = {}
        auth_hash['info']['email'] = email
        auth_hash['provider'] = 'identity'
        auth_hash['uid'] = identity.id

        Member.from_auth(auth_hash)
      end
    end

  end

end
