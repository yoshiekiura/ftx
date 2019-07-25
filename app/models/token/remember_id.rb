class Token::RememberId < ::Token
  attr_accessor :email

  before_validation :set_member, on: :create

  validates_presence_of :email, on: :create

  after_create :send_token

  private

  def set_member
    if member = Member.find_by_email(self.email)
      self.member = member
    end
  end

  def send_token
    TokenMailer.remember_id(member.email, member.identity.client_uuid)
  end
end
