require 'spec_helper'

describe 'withdraw', js: true do
  let!(:identity_normal) { create :identity }
  let!(:identity) { create :identity, email: Member.admins.first }
  let!(:member) { create :member, email: identity_normal.email }
  let!(:admin_member) { create :admin_member, :app_two_factor_activated, email: identity.email}
  let!(:two_factor) { admin_member.app_two_factor }

  let!(:account) do
    admin_member.get_account(:brl).tap { |a| a.update_attributes locked: 8000, balance: 10000 }
  end

  let!(:withdraw) { create :bank_withdraw, member: admin_member, sum: 5000, aasm_state: :accepted, account: account}

  before do
    Withdraw.any_instance.stubs(:validate_password).returns(true)
    two_factor.refresh!
  end

  def visit_admin_withdraw_page

    login identity
    visit settings_path
    find('#admin_icon').click

    fill_in 'two_factor_otp', with: two_factor.now
    click_on t('two_factors.index.verify')

  end

  # it 'admin view withdraws' do
  #   pending
  #   visit_admin_withdraw_page
  #
  #   click_on I18n.t('admin_header.withdraws')
  #   click_on I18n.t('admin.deposits.banks.show.target_deposit')
  #
  #   expect(page).to have_content(withdraw.id)
  #
  #
  # end

  it 'admin approve withdraw' do
    pending
    visit_admin_withdraw_page

    click_on I18n.t('admin_header.withdraws')
    click_on I18n.t('admin.deposits.banks.show.target_deposit')

    expect(current_path).to eq(admin_withdraws_banks_path)

    expect(account.reload.locked).to be_d '8000'
    expect(account.reload.balance).to be_d '10000'
  end

  it 'admin reject withdraw' do
    pending
    visit_admin_withdraw_page

    click_on I18n.t('admin_header.withdraws')
    click_on I18n.t('admin.deposits.banks.show.target_deposit')

    expect(current_path).to eq(admin_withdraws_banks_path)
    expect(account.reload.locked).to be_d '8000'
    expect(account.reload.balance).to be_d '10000.0000'
  end
end
