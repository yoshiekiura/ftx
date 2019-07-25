require 'spec_helper'

describe FundSource do

  context '#label' do
    context 'for btc' do
      let(:fund_source) { build(:btc_fund_source) }
      subject { fund_source }

      its(:label) { should eq("#{fund_source.uid} (bitcoin)") }
    end

    context 'bank' do
      let(:fund_source) { build(:brl_fund_source) }
      subject { fund_source }

      its(:label) { should eq('Banco do Brasil S.A.#****1234') }
    end
  end

end
