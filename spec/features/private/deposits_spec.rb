begin
require 'spec_helper'

feature 'deposits', js: true do
  let(:identity) { create :identity }
  let!(:member) { create :verified_member, :app_two_factor_activated, email: identity.email}

  let!(:deposit_btc) { create :deposit, currency: 'btc', member: member, fund_uid: '123', fund_extra: '333'}
  let!(:deposit_ripple) { create :deposit, currency: 'xrp', member: member, fund_uid: '321', fund_extra: '333'}


  before(:each) do
    login identity
  end


  scenario 'user can list deposits BTC and Ripple decimals' do
    visit funds_path + '#/deposits/brl'
    find("a[href='#dep-history']").click
    expect(page).to have_content '.000000'
    expect(page).to have_content '.00000000'
  end


end
end
