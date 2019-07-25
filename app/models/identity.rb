class Identity < OmniAuth::Identity::Models::ActiveRecord

  # TODO: Change it to use :client_uuid
  auth_key :client_uuid
  #auth_key :email

  attr_accessor :old_password

  MAX_LOGIN_ATTEMPTS = 5

  validates :email, presence: true, uniqueness: true, email: true
  validates :client_uuid, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6, maximum: 64 }
  validates :password_confirmation, presence: true, length: { minimum: 6, maximum: 64 }

  before_validation :sanitize
  before_validation :set_client_uuid


  has_one :member, foreign_key: 'identity_id'

  def increment_retry_count
    self.retry_count = (retry_count || 0) + 1
  end

  def too_many_failed_login_attempts
    retry_count.present? && retry_count >= MAX_LOGIN_ATTEMPTS
  end

  private

  def sanitize
    self.email.try(:downcase!)
  end

  def set_client_uuid
    return unless self.client_uuid.nil?
    id = get_rand
    while redis.sismember(key_for, id)
      id = get_rand
    end
    redis.sadd(key_for, id)
    self.client_uuid = id
  end

  def key_for
    "peatio:members:client_uuid"
  end

  def get_rand
    rand(8 ** 8).to_s.rjust(8,'0')
  end

  def redis
    @r ||= KlineDB.redis
  end

end
