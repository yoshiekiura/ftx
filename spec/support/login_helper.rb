def login(identity, otp: nil, password: nil)
  visit signin_path
  expect(current_path).to eq(signin_path)

  identity_reload = Identity.find_by_email(identity.email)
  within 'form#new_identity' do
    fill_in 'identity_client_uuid', with: identity_reload.client_uuid
    fill_in 'identity_password', with: (password || identity.password)
    click_on I18n.t('header.signin').upcase
  end

  if otp
    fill_in 'google_auth_otp', with: otp
    click_on I18n.t('helpers.submit.two_factor.create')
  end
end

def signout
  click_link t('header.signout')
end

def check_signin
  expect(page).not_to have_content(I18n.t('header.signin'))
end

alias :signin :login
