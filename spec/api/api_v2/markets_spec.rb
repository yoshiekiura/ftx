begin
require 'spec_helper'

describe APIv2::Markets do

  describe "GET /api/v2/markets" do
    it "should all available markets" do
      get '/api/v2/markets'
      response.should be_success
      response.body.should == '[{"id":"btcbrl","name":"BTC/BRL"},{"id":"bchbrl","name":"BCH/BRL"},{"id":"btgbrl","name":"BTG/BRL"}]'
    end
  end

end
end