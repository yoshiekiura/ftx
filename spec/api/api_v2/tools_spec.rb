require 'spec_helper'

describe APIv2::Tools do

  describe "GET /api/v2/timestamp" do
    it "returns server time" do
      get '/api/v2/timestamp'
      response.should be_success
    end
  end

  describe "GET /api/v2/signature" do
    it "returns fake signature" do
      host! 'cointrade.cx'
      get '/api/v2/signature', { secret_key: 'abcd', seed: 'b=c' }
      response.should be_success
    end
  end

  describe "POST /api/v2/stratum/operation" do
    let!(:event)  { create(:stratum_event,
                           operation_id: 1,
                           operation_etxid: nil,
                           operation_status: 'new') }

    context "successful" do
      it "should update Stratum event" do
        pending
        post "/api/v2/stratum/operation", {api_ts: 1,
                                           api_sig: '5e7f52c49e14d218928032beae705a99d87c3827e2b1569c0bbc5dbc35b9e2cf',
                                           payload: '{"operation_id":1,"operation_etxid":"xxxxx"}' }
        response.should be_success
        JSON.parse(response.body)['status'].should == true
      end
    end

    context "failed" do
      it "should return order not found error" do
        post "/api/v2/stratum/operation", params: {api_ts: '0'}
        response.code.should == '400'
        JSON.parse(response.body)['error']['code'].should == 1001
      end
    end

  end


end
