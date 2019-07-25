class Authentication < ActiveRecord::Base
  belongs_to :member

  validates :provider, presence: true, uniqueness: { scope: :member_id }
  validates :uid,      presence: true, uniqueness: { scope: :provider }

  class << self
    # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    def locate(auth)
      uid      = auth['uid'].to_s
      provider = auth['provider']
      find_by_provider_and_uid provider, uid
    end

    def build_auth(auth)
      new \
        uid:      auth['uid'],
        provider: auth['provider'],
        token:    auth['credentials'].try(:[], 'token'),
        secret:   auth['credentials'].try(:[], 'secret'),
        nickname: auth['info'].try(:[], 'nickname')
    end
     # add_transaction_tracer :locate,
     #                        :name => 'locate',
     #                        :category => "Authentication/locate"
     # add_transaction_tracer :build_auth,
     #                        :name => 'build_auth',
     #                        :category => "Authentication/build_auth"

  end
end
