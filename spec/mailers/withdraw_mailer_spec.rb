require "spec_helper"

describe WithdrawMailer do
  describe "withdraw_state" do
    let(:withdraw) { create :satoshi_withdraw }
    let(:mail) do
      withdraw.cancel!
      WithdrawMailer.withdraw_state(withdraw.id)
    end

    it "renders the headers" do
      mail.subject.should eq("[Cointrade] Atualização do status do seu saque")
      mail.to.should eq([withdraw.member.email])
      mail.from.should eq([ENV['SYSTEM_MAIL_FROM']])
    end

    it "renders the body" do
      mail.body.encoded.should match("canceled")
    end
  end

  describe "submitted" do
    let(:withdraw) { create :satoshi_withdraw }
    let(:mail) do
      withdraw.submit!
      WithdrawMailer.submitted(withdraw.id)
    end

    it "renders the headers" do

      mail.subject.should eq("[Cointrade] Atualização do status do seu saque")
      mail.to.should eq([withdraw.member.email])
      mail.from.should eq([ENV['SYSTEM_MAIL_FROM']])
    end

    it "renders the body" do
      pending
      mail.body.encoded.should match("Sua requisição de saque de BTC foi gerada com sucesso.")
    end
  end

  describe "done" do
    let(:withdraw) { create :satoshi_withdraw }
    let(:mail) do
      withdraw.submit!
      withdraw.accept!
      withdraw.process!
      withdraw.succeed!
      WithdrawMailer.done(withdraw.id)
    end

    it "renders the headers" do
      pending
      mail.subject.should eq("[Cointrade] Atualização do status do seu saque")
      mail.to.should eq([withdraw.member.email])
      mail.from.should eq([ENV['SYSTEM_MAIL_FROM']])
    end

    it "renders the body" do
      pending
      mail.body.encoded.should match("Sua requisição de saque de BTC foi concluída.")
    end
  end
end
