
Recaptcha.configure do |config|
  config.site_key  = ENV["SITE_CAPTCHA_KEY"]
  config.secret_key = ENV["SITE_CAPTCHA_SECRET_KEY"]
end