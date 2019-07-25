begin
require 'spec_helper'

describe Market do

  context 'visible market' do
    # it { expect(Market.orig_all.count).to eq(2) }
    it { expect(Market.all.count).to eq(3) }
  end

  context 'markets hash' do
    it "should list all markets info" do
      pending
      Market.to_hash.should == {:btcbrl=>{:name=>"BTC/BRL",
                                          :base_unit=>"btc",
                                          :base_fixed=>4,
                                          :quote_unit=>"brl"},
                                :bchbrl=>{:name=>"BCH/BRL",
                                          :base_unit=>"bch",
                                          :base_fixed=>4,
                                          :quote_unit=>"brl"},
                                :btgbrl=>{:name=>"BTG/BRL",
                                          :base_unit=>"btg",
                                          :base_fixed=>4,
                                          :quote_unit=>"brl"}}
    end
  end

  context 'market attributes' do
    subject { Market.find('btcbrl') }

    its(:id)         { should == 'btcbrl' }
    its(:name)       { should == 'BTC/BRL' }
    its(:base_unit)  { should == 'btc' }
    its(:quote_unit) { should == 'brl' }
    its(:visible)    { should be_true }
  end

  context 'enumerize' do
    subject { Market.enumerize }

    it { should be_has_key :btcbrl }
    it { should be_has_key :btgbrl }
  end

  context 'shortcut of global access' do
    subject { Market.find('btcbrl') }

    its(:bids)   { should_not be_nil }
    its(:asks)   { should_not be_nil }
    its(:trades) { should_not be_nil }
    its(:ticker) { should_not be_nil }
  end

end
end