Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, fields: [:email], on_failed_registration: IdentitiesController.action(:new)
  if ENV['WEIBO_AUTH'] == "true"
    provider :weibo, ENV['WEIBO_KEY'], ENV['WEIBO_SECRET']
  end
end

OmniAuth.config.on_failure = lambda do |env|
  SessionsController.action(:failure).call(env)
end

OmniAuth.config.logger = Rails.logger

module OmniAuth
  module Strategies
   class Identity
     def request_phase
       redirect '/signin'
     end

     def registration_form
       redirect '/signup'
     end

     def registration_phase
       if accounts_limit_reach
         registration_form
       else
         attributes = (options[:fields] + [:password, :password_confirmation]).inject({}){|h,k| h[k] = request[k.to_s]; h}
         @identity = model.create(attributes)
         if @identity.persisted?
           env['PATH_INFO'] = callback_path
           callback_phase
         else
           if options[:on_failed_registration]
             self.env['omniauth.identity'] = @identity
             options[:on_failed_registration].call(self.env)
           else
             registration_form
           end
         end
       end
     end

     private

     def accounts_limit_reach
       member_count = Member.count
       limit_account = Figaro.env.limit_account.to_i

       return member_count >= limit_account && limit_account != -1
     end

   end
 end
end

begin
  KlineDB.redis.del("peatio:members:client_uuid")
  Identity.all.each do |identity|
    KlineDB.redis.sadd("peatio:members:client_uuid", identity.client_uuid) unless identity.client_uuid.nil?
  end
rescue
  Rails.logger.error "Failed to process: #{$!}"
  Rails.logger.error $!.backtrace.join("\n")
end