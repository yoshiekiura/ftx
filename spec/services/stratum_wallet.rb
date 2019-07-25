require 'spec_helper'

describe StratumWallet do

  let(:success_generate_id) { Stratum::Response.new("{\"status\":\"ok\",
      \"message\":\"Request ok\",\"data\":{\"wallet_id\":44,\"wallet_eid\":4,
      \"wallet_label\":\"wallet currency btg\",\"wallet_balance\":1.1,
      \"wallet_group_id\":6,\"wallet_group_label\":\"cointrade\",
      \"wallet_group_eid\":1,\"wallet_type\":\"checking\",
      \"currency_name\":\"Bitcoin Gold\",\"currency\":\"BTG\",
      \"currency_type\":\"crypto\",\"currency_unit\":\"Bitcoin Gold\",
      \"currency_unit_symbol\":\"\xE2\x82\xBF\",\"currency_unit_digits\":8}}") }

  let(:fail_check_id) { Stratum::Response.new("{\"status\":\"fail\",
      \"message\":\"Request fail\",\"data\":{}}") }

  let(:success_check_id) { Stratum::Response.new("{\"status\":\"ok\",
      \"message\":\"Request ok\",\"data\":[{\"wallet_id\":44,\"wallet_eid\":4,
      \"wallet_label\":\"wallet currency btg\",\"wallet_balance\":1.1,
      \"wallet_group_id\":6,\"wallet_group_label\":\"cointrade\",
      \"wallet_group_eid\":1,\"wallet_type\":\"checking\",
      \"currency_name\":\"Bitcoin Gold\",\"currency\":\"BTG\",
      \"currency_type\":\"crypto\",\"currency_unit\":\"Bitcoin Gold\",
      \"currency_unit_symbol\":\"\xE2\x82\xBF\",\"currency_unit_digits\":8}]}") }

  let(:fail_response_balance) { Stratum::Response.new("{\"status\":\"fail\",
      \"message\":\"Request fail\",\"data\":{}}") }

  let(:success_response_balance) { Stratum::Response.new("{\"status\":\"ok\",
      \"message\":\"Request ok\",\"data\":{\"wallet_id\":44,\"wallet_eid\":4,
      \"wallet_label\":\"wallet currency btg\",\"wallet_balance\":1.1,
      \"wallet_group_id\":6,\"wallet_group_label\":\"cointrade\",
      \"wallet_group_eid\":1,\"wallet_type\":\"checking\",
      \"currency_name\":\"Bitcoin Gold\",\"currency\":\"BTG\",
      \"currency_type\":\"crypto\",\"currency_unit\":\"Bitcoin Gold\",
      \"currency_unit_symbol\":\"\xE2\x82\xBF\",\"currency_unit_digits\":8}}") }

  context "Validating creation" do
    it "should raise error" do
      Stratum::Wallet.stubs(:list).returns(fail_check_id)
      Stratum::Wallet.stubs(:create).returns(fail_check_id)

      expect {
        currency = Currency.find_by_id(2)
        StratumWallet.get_id(1,1,currency)
        AMQPQueue.expects(:enqueue).with(anything).times(1)
      }.to raise_error(StandardError)
    end

    it "should locate one" do
      Stratum::Wallet.stubs(:list).returns(success_check_id)

      currency = Currency.find_by_id(2)
      id = StratumWallet.get_id(1,1,currency)
      id.should == 44
    end

    it "should create one" do
      Stratum::Wallet.stubs(:list).returns(fail_check_id)
      Stratum::Wallet.stubs(:create).returns(success_generate_id)

      currency = Currency.find_by_id(2)
      id = StratumWallet.get_id(1,1,currency)
      id.should == 44
    end

  end

  context "Validating balance" do
    it "should return ZERO value of balance" do
      Net::HTTP.any_instance.stubs(:request).raises(Errno::ECONNREFUSED)

      balance = StratumWallet.get_balance(1)
      balance.should == 0
    end

    it "should return ZERO value of balance" do
      Stratum::Wallet.stubs(:get).returns(fail_response_balance)

      balance = StratumWallet.get_balance(1)
      balance.should == 0
    end

    it "should return api value of balance" do
      Stratum::Wallet.stubs(:get).returns(success_response_balance)

      balance = StratumWallet.get_balance(1)
      balance.should == 1.1
    end
  end

end
