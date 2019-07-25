require "spec_helper"

describe MemberMailer do
  describe "notify_signin" do
    let(:member) { create :member }
    let(:mail) { MemberMailer.notify_signin(member.id) }

    it "renders the headers" do
      pending
      mail.subject.should eq("[Cointrade] Você acabou de entrar no sistema")
      mail.to.should eq([member.email])
      mail.from.should eq([ENV['SYSTEM_MAIL_FROM']])
    end

    it "renders the body" do
      pending
      mail.body.encoded.should match("Você acabou de entrar no sistema")
    end
  end

end
