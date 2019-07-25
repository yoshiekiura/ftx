require 'spec_helper'

feature 'My Tickers' do
  let!(:identity) { create :identity }
  let!(:member) { create :member, :activated, email: identity.email  }

  scenario 'all Tickers' do
    login identity
    visit market_v2_path(:id => "btcbrl")
    expect(page).to have_text("BCH/BRL0.00.00%0.0BTG/BRL0.00.00%0.0BTC/BRL0.00.00%0.0")
  end

end