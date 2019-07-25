class Currency < ActiveYamlBase
  #require 'newrelic_rpm'
   # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  include International
  include ActiveHash::Associations

  field :visible, default: true

  self.singleton_class.send :alias_method, :all_with_invisible, :all
  def self.all
    all_with_invisible.select{ |c| c[:maintenance] == false &:visible}
  end

  def self.all_no_filter
    all_with_invisible.select &:visible
  end

  def self.all_no_filter
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|memo, i| memo[i.code.to_sym] = i.id; memo}
  end

  def self.codes
    @keys ||= all_no_filter.map &:code
  end

  def self.ids
    @ids ||= all.map &:id
  end

  def self.assets(code)
    find_by_code(code)[:assets]
  end

  def precision
    self[:precision]
  end

  def api
    raise unless coin?
    CoinRPC[code]
  end

  def fiat?
    not coin?
  end

  def stratum_wallet_id
    Rails.cache.read(stratum_cache_key) || 0
  end

  def update_stratum_wallet_id(id)
    Rails.cache.write(stratum_cache_key, id)
  end

  def stratum_cache_key
    "stratum:currency:#{code}:wallet_id"
  end

  def withdraw_fee
    Rails.cache.read(withdraw_fee_cache_key) || 0
  end

  def refresh_withdraw_fee
    Rails.cache.write(withdraw_fee_cache_key, StratumOperation.withdraw_fee(code)) if coin?
  end

  def withdraw_fee_cache_key
    "peatio:hotwallet:#{code}:withdraw_fee"
  end

  def balance
    StratumWallet.get_balance(self[:stratum_wallet_id]) || 0
  end

  def refresh_balance
    Rails.cache.write(balance_cache_key, StratumWallet.get_balance(self[:stratum_wallet_id])) if coin?
  end

  def balance_cache_key
    "peatio:hotwallet:#{code}:balance"
  end

  def decimal_digit
    self.try(:default_decimal_digit) || (fiat? ? 2 : 4)
  end

  def blockchain_url(txid)
    raise unless coin?
    blockchain.gsub('#{txid}', txid.to_s)
  end

  def address_url(address)
    raise unless coin?
    self[:address_url].try :gsub, '#{address}', address
  end

  def quick_withdraw_max
    @quick_withdraw_max ||= BigDecimal.new self[:quick_withdraw_max].to_s
  end

  def as_json(options = {})
    {
      key: key,
      code: code,
      coin: coin,
      blockchain: blockchain
    }
  end

  def summary
    locked = Account.locked_sum(code)
    balance = Account.balance_sum(code)
    sum = locked + balance

    coinable = self.coin?
    hot = coinable ? self.balance : nil

    {
      name: self.code.upcase,
      sum: sum,
      balance: balance,
      locked: locked,
      coinable: coinable,
      hot: hot
    }
  end
  # add_transaction_tracer :all,
  #                        :name => 'all',
  #                        :category => "Currency/all"
  # add_transaction_tracer :enumerize,
  #                        :name => 'enumerize',
  #                        :category => "Currency/enumerize"
  # add_transaction_tracer :codes,
  #                        :name => 'codes',
  #                        :category => "Currency/codes"
  # add_transaction_tracer :ids,
  #                        :name => 'ids',
  #                        :category => "Currency/ids"
  # add_transaction_tracer :precision,
  #                        :name => 'precision',
  #                        :category => "Currency/precision"
  # add_transaction_tracer :update_stratum_wallet_id,
  #                        :name => 'update_stratum_wallet_id',
  #                        :category => "Currency/update_stratum_wallet_id"
  # add_transaction_tracer :stratum_cache_key,
  #                        :name => 'stratum_cache_key',
  #                        :category => "Currency/stratum_cache_key"
  # add_transaction_tracer :refresh_withdraw_fee,
  #                        :name => 'refresh_withdraw_fee',
  #                        :category => "Currency/refresh_withdraw_fee"
  # add_transaction_tracer :withdraw_fee_cache_key,
  #                        :name => 'withdraw_fee_cache_key',
  #                        :category => "Currency/withdraw_fee_cache_key"
  # add_transaction_tracer :balance,
  #                        :name => 'balance',
  #                        :category => "Currency/balance"
  # add_transaction_tracer :refresh_balance,
  #                        :name => 'refresh_balance',
  #                        :category => "Currency/refresh_balance"
  # add_transaction_tracer :balance_cache_key,
  #                        :name => 'balance_cache_key',
  #                        :category => "Currency/balance_cache_key"
  # add_transaction_tracer :decimal_digit,
  #                        :name => 'decimal_digit',
  #                        :category => "Currency/decimal_digit"
  # add_transaction_tracer :blockchain_url,
  #                        :name => 'blockchain_url',
  #                        :category => "Currency/blockchain_url"
  # add_transaction_tracer :address_url,
  #                        :name => 'address_url',
  #                        :category => "Currency/address_url"
  # add_transaction_tracer :quick_withdraw_max,
  #                        :name => 'quick_withdraw_max',
  #                        :category => "Currency/quick_withdraw_max"
  # add_transaction_tracer :summary,
  #                        :name => 'summary',
  #                        :category => "Currency/summary"
end
