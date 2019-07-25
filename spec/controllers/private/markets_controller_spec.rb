require 'spec_helper'

describe Private::Marketsv2Controller do
  let(:member) { create :activated_member }
  before { session[:member_id] = member.id }

  # context "logged in user" do
  #   describe "GET /v2/markets/btcbrl" do
  #     before { get :show, data }
  #
  #     it { should respond_with :ok }
  #   end
  # end
  #
  # context "non-login user" do
  #   before { session[:member_id] = nil }
  #
  #   describe "GET /v2/markets/btcbrl" do
  #     before { get :show, data }
  #
  #     it { should respond_with 302 }
  #     it { expect(assigns(:member)).to be_nil }
  #   end
  # end

  private

  def data
    {
      id: 'btcbrl',
      market: 'btcbrl',
      ask: 'btc',
      bid: 'brl'
    }
  end

end
