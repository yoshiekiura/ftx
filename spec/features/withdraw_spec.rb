require 'spec_helper'

describe 'withdraw', js: true do
  let!(:identity) { create :identity }
  let!(:member) { create :verified_member, :app_two_factor_activated, email: identity.email}
  let!(:two_factor) { member.app_two_factor }

  let(:radio_label) do
    "#{member.name} @ #{identity.email}"
  end

  before do
    Withdraw.any_instance.stubs(:examine).returns(true)
    Withdraw.any_instance.stubs(:validate_password).returns(true)
    two_factor.refresh!

    CoinRPC.any_instance.stubs(:validateaddress).returns({isvalid: true, ismine: false})

    btc_account = member.get_account(:btc)
    btc_account.update_attributes balance: 1000
    brl_account = member.get_account(:brl)
    brl_account.update_attributes balance: 300

    @label = 'common address'
    @bank = 'Banco do Brasil'
    @btc_addr = create :btc_fund_source, extra: @label, uid: '1btcaddress', member: member
    @brl_addr = create :brl_fund_source, extra: '_001', uid: '1234566890', member: member

  end

  it 'allows user to add a BTC withdraw address, withdraw BTC' do
    pending
    login identity

    visit funds_path + '#/withdraws/btc'

    expect(page).to have_text("1,000.000")

    # submit withdraw request
    submit_satoshi_withdraw_request 600

    # using_wait_time 10 do
    #   click_on "HIST�RICO"
    #   expect(page).to have_text("600,0")
    # end
  end

  it 'prevents withdraws that the account has no sufficient balance' do
    pending
    login identity
    visit funds_path + '#/withdraws/brl'
    submit_bank_withdraw_request 800.00
    expect(page).to have_text(I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor'))
  end

  # it 'testing calculate fee do Withdraw BRL others' do
  #   login identity
  #
  #   visit funds_path + '/#withdraws/brl'
  #   submit_bank_withdraw_request 100
  #   visit funds_path + '/#withdraws/brl'
  #   expect(page).to have_text("10.90")
  # end

  private

  def submit_bank_withdraw_request amount
    select @bank, from: 'fund_source'
    fill_in 'withdraw_sum', with: amount
    fill_in 'two_factor_otp', with: two_factor.now
    click_on I18n.t 'js.submit'
  end

  def submit_satoshi_withdraw_request amount
    select @label, from: 'fund_source'
    fill_in 'withdraw-amount', with: amount
    fill_in 'two_factor_otp', with: two_factor.now
    click_on I18n.t 'js.submit'
  end

end
