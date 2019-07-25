require 'spec_helper'

feature 'show account info', js: true do
  let(:identity) { create :identity }
  let(:other_member) { create :member }
  let!(:member) { create :verified_member, :app_two_factor_activated, email: identity.email}
  let!(:bid_account) do
    member.get_account('brl').tap { |a| a.update_attributes locked: 400, balance: 1000 }
  end
  let!(:ask_account) do
    member.get_account('btc').tap { |a| a.update_attributes locked: 400, balance: 2000 }
  end
  let!(:ask_order) { create :order_ask, price: '23.6', member: member }
  let!(:bid_order) { create :order_bid, price: '21.3' }
  let!(:ask_name) { I18n.t('currency.name.btc') }

  scenario 'user can cancel his own order' do

    pending
    login identity
    visit market_v2_path(:id => "btcbrl")

    #AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: ask_order.to_matching_attributes)
      first('.order-pair').click

      expect(page.all('#btcbrl-all .order-pair-row.columns').count).to eq(1) # can only see his order

      expect(page).to have_selector('.column.td > i.fas.fa-times')
    #


  end
end
