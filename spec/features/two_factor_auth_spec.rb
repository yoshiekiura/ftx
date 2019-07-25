require 'spec_helper'

describe '2-step verification' do
  let!(:identity) { create :identity }
  let!(:member) { create :member, email: identity.email }

  it 'allows user to set it up and disable it' do

    # signin identity
    #
    # # enable
    # click_on t('private.settings.index.two_factor_auth.enable')
    #
    # secret = page.find('#google_auth_otp_secret').value
    # fill_in 'google_auth_otp', with: ROTP::TOTP.new(secret).now
    # click_on t('verify.google_auths.show.submit')
    # expect(page).to have_content t('verify.google_auths.update.notice')
    #
    # # signin again
    # signout
    # signin identity
    #
    # # disable
    # click_link t('private.settings.index.two_factor_auth.disable')
    #
    # fill_in 'two_factor_otp', with: ROTP::TOTP.new(secret).now
    # click_on t('verify.google_auths.edit.submit')
    # expect(page).to have_content t('verify.google_auths.destroy.notice')
    #
    # signout
    # signin identity
    # check_signin
  end
end
