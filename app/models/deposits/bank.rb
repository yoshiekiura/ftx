module Deposits
  class Bank < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Bankable
    include ::FundSourceable

    after_create :invoke_samurai

    validate :samurai_waiting_ted_today

    def samurai_waiting_ted_today
      if samurai_waiting_today? and self.txid == 'TED'
        errors.add(:txid, I18n.translate("activerecord.errors.models.deposit.bank.ted"))
      end
    end

    def deposit_id
      return self.txid.split(':')[0] == "TED" ? cpf : self.txid.split(':')[2]
    end

    def charge!(txid)
      with_lock do
        submit!
        accept!
        touch(:done_at)
        update_attribute(:txid, txid)
        SystemMailer.samurai_status_change(self)
      end
    end

    def reject_it!(txid)
      with_lock do
        submit!
        reject!
        touch(:done_at)
        update_attribute(:txid, txid)
        SystemMailer.samurai_status_change(self)
      end
    end

    def samurai_details
      cpf = self.txid.split(':')[1]
      type = self.txid.split(':')[0]
      samurai_code = type == "TED" ? cpf : self.txid.split(':')[2]
      return cpf, type, samurai_code
    end

    private

    def cpf
      self.fund_uid.split('/')[0].gsub(/[^\d]/, '')
    rescue
      Rails.logger.error "Failed to parse CPF: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      return ''
    end

    def bank_code
      return self.fund_extra.gsub('_', '')
    rescue
      Rails.logger.error "Failed to parse bank code: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      return ''
    end

    def bank_branch
      details = self.fund_uid.split('/')
      return '' if details.size == 0

      return details[1].gsub(/[^\d]/, '')
    rescue
      Rails.logger.error "Failed to parse bank branch: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      return ''
    end

    def bank_account
      details = self.fund_uid.split('/')
      return '' if details.size == 0

      base = details[2].gsub(/[^\d]/, '')
      digit = details[3].gsub(/[^\d]/, '')

      return "#{base}-#{digit}"
    rescue
      Rails.logger.error "Failed to parse bank account: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      return ''
    end

    def invoke_samurai
      payload = samurai_payload
      unless payload.nil?
        response  = Samurai::Order.create(samurai_payload)

        if response.status == :ok
          samurai_code = response.data[:code]
          samurai_id = response.data[:id]
          update_attribute(:txid, "#{self.txid}:#{cpf}:#{samurai_code}:#{samurai_id}")
        end
      end
    rescue
      SystemMailer.samurai_persistence_error(payload, $!.message, $!.backtrace.join("\n"))
      Rails.logger.error "Failed to process Samurai: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def samurai_waiting_today?
      return Deposit.where(type:'Deposits::Bank').
          where("txid like 'TED%'").
          where(amount:self.amount).
          where('created_at BETWEEN ? AND ?', Date.today.midnight, DateTime.parse(DateTime.now.strftime("%Y-%m-%dT23:59:59%z"))).
          with_aasm_state(:submitting, :submitted).
          where(member_id: self.member_id).count > 0
    end

    def samurai_payload
      payload = '{ "email": "SUPPORT_MAIL",
                   ATTACH
                    "coin": "bitcoin",
            "amount_asked": AMOUNT_ASKED_TO_CHECK,
               "bank_code": "BANK_CODE",
             "bank_branch": "BANK_BRANCH",
            "bank_account": "BANK_ACCOUNT",
                    "fiat": "brl",
                    "fake": true,
                  "source": "cointrade",
                 "address": "fake" }'

      attach = case self.txid
                when 'TEF'
                  ' '
                when 'TED'
                  '"document": "CPF",'
                end

      payload = payload.gsub('ATTACH', attach)
      payload = payload.gsub('SUPPORT_MAIL', ENV['SUPPORT_MAIL'])
      payload = payload.gsub('CPF', cpf)
      payload = payload.gsub('AMOUNT_ASKED_TO_CHECK', self.amount.to_s)
      payload = payload.gsub('BANK_CODE', bank_code)
      payload = payload.gsub('BANK_BRANCH', bank_branch)
      payload = payload.gsub('BANK_ACCOUNT', bank_account)

      payload
    end



  end
end
