begin
require 'spec_helper'

feature 'withdraws', js: true do
  let(:identity) { create :identity }
  let!(:member) { create :verified_member, :app_two_factor_activated, email: identity.email}
  let!(:withdraw_btc) { create :satoshi_withdraw, currency: 'btc', member: member}
  let!(:xrp_fund_source) { create :xrp_fund_source }
  let!(:withdraw_ripple) { create :satoshi_withdraw, currency: 'xrp', member: member, fund_source_id: xrp_fund_source, type: 'Withdraws::Xrp'}

  before do
    login identity
    visit funds_path + '#/withdraws/brl'
  end

  scenario 'user can list withdraws BTC and Ripple decimals' do
    find("a[href='#dep-history']").click
    expect(page).to have_content '.000000'
    expect(page).to have_content '.00000000'
  end

end
end
