begin
require 'spec_helper'

feature 'my trades', js: true do
  let(:identity) { create :identity }
  let(:member) { create :member, email: identity.email}

  let!(:ask_order) { create :order_ask, price: '23.6', member: member }
  let!(:bid_order) { create :order_bid, price: '21.3', member: member }

  let!(:trades_bid) {[
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: Date.today.midnight),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: Date.today.midnight),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 1.day.ago),
      create(:trade, bid: bid_order, currency: :btgbrl, created_at: 29.day.ago)
  ]}

  let!(:trades_ask) {[
      create(:trade, ask: ask_order, currency: :btcbrl, created_at: 2.days.ago),
      create(:trade, ask: ask_order, currency: :btcbrl, created_at: 2.days.ago),
      create(:trade, ask: ask_order, currency: :btcbrl, created_at: 2.days.ago),
      create(:trade, ask: ask_order, currency: :btcbrl, created_at: 2.days.ago)
  ]}

  before(:each) do
    login identity
    visit trade_history_v2_path
  end


  scenario 'user select and search by date with radio button (Today / Week Ago / Month Ago)' do

    # find("#select_date option[value='today']").select_option
    # click_on I18n.t('private.history.filters.search')
    #
    #
    # find("#select_date option[value='one_week']").select_option
    # click_on I18n.t('private.history.filters.search')
    #
    #
    # find("#select_date option[value='one_month']").select_option
    # click_on I18n.t('private.history.filters.search')


  end

  scenario 'user select and search by date with start and end inputs' do
    pending
    fill_in "start", with: 3.day.ago.midnight
    fill_in "end", with: 2.day.ago.end_of_day

    click_on I18n.t('private.history.filters.search')

    page.all('tbody#mytrades tr').count.should == 4

  end

  scenario 'user select and search by side (sell / buy / all)' do
    pending
    find("#select_side option[value='sell']").select_option
    click_on I18n.t('private.history.filters.search')

    find("#select_side option[value='buy']").select_option
    click_on I18n.t('private.history.filters.search')

    find("#select_side option[value='']").select_option
    click_on I18n.t('private.history.filters.search')



  end


end
end
