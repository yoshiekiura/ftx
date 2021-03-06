class Trade < ActiveRecord::Base
  #require 'newrelic_rpm'
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  extend ActiveHash::Associations::ActiveRecordExtensions
  ZERO = '0.0'.to_d

  extend Enumerize
  enumerize :trend, in: {:up => 1, :down => 0}
  enumerize :currency, in: Market.enumerize, scope: true


  belongs_to :ask, class_name: 'OrderAsk', foreign_key: 'ask_id'
  belongs_to :bid, class_name: 'OrderBid', foreign_key: 'bid_id'

  belongs_to :ask_member, class_name: 'Member', foreign_key: 'ask_member_id'
  belongs_to :bid_member, class_name: 'Member', foreign_key: 'bid_member_id'

  validates_presence_of :price, :volume, :funds

  scope :h24, -> { where("created_at > ?", 24.hours.ago) }
  scope :last_existent, -> { where("price != 0").reverse_order.first }
  scope :latest, -> { order("id").reverse_order.first }

  attr_accessor :side

  alias_method :sn, :id

  def market
    Market.find(self.ask.ask+self.bid.bid)
  end

  class << self
    # include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def latest_price(currency)
      with_currency(currency).order(:id).reverse_order
        .limit(1).first.try(:price) || "0.0".to_d
    end

#Cointrade alteracao para implementacao de bitvalor sellside e buyside desfeito
    #def filter(market, timestamp, from, to, limit, order, originator)
    def filter(market, timestamp, from, to, limit, order)  
      trades = with_currency(market).order(order)
      trades = trades.limit(limit) if limit.present?
      trades = trades.where('created_at <= ?', timestamp) if timestamp.present?
      trades = trades.where('id > ?', from) if from.present?
      trades = trades.where('id < ?', to) if to.present?
      #Cointrade coin alteracao para implementacao de bitvalor sellside e buyside desfeito
       #if originator == 'buyside'
       #  trades = trades.where('ask_id < bid_id') if originator.present?
       #elsif originator == 'sellside'
       #  trades = trades.where('ask_id > bid_id') if originator.present?
       #end 
      #Cointrade fim da alteracao

      #Cointrade - nova alteracao sell e buy side
      trades.each do |trade|
        trade.side = trade.ask_id < trade.bid_id ? 'buy' : 'sell'
      end 
      #Cointrade - fim alteracao      

      trades
    end
#Cointrade fim da alteracao

    def for_member(currency, member, options={})
      trades = filter(currency, options[:time_to], options[:from], options[:to], options[:limit], options[:order]).where("ask_member_id = ? or bid_member_id = ?", member.id, member.id)
      trades.each do |trade|
        trade.side = trade.ask_member_id == member.id ? 'ask' : 'bid'
      end
    end

    # add_transaction_tracer :latest_price,
    #                        :name => 'latest_price',
    #                        :category => "Trade/latest_price"
    # add_transaction_tracer :filter,
    #                        :name => 'filter',
    #                        :category => "Trade/filter"
    # add_transaction_tracer :for_member,
    #                        :name => 'for_member',
    #                        :category => "Trade/for_member"
  end

  def trigger_notify
    ask.member.notify 'trade', for_notify('ask')
    bid.member.notify 'trade', for_notify('bid')
  end

  def for_notify(kind=nil)
    {
      id:     id,
      kind:   kind || side,
      at:     created_at.to_i,
      price:  price.to_s  || ZERO,
      volume: volume.to_s || ZERO,
      market: ask.ask+bid.bid

    }
  end

  def for_global
    {
      tid:    id,
      type:   trend == 'down' ? 'sell' : 'buy',
      date:   created_at.to_i,
      price:  price.to_s || ZERO,
      amount: volume.to_s || ZERO,
      market: ask.ask+bid.bid
    }
  end

  # add_transaction_tracer :trigger_notify,
  #                        :name => 'trigger_notify',
  #                        :category => "Trade/trigger_notify"
  # add_transaction_tracer :for_notify,
  #                        :name => 'for_notify',
  #                        :category => "Trade/for_notify"
  # add_transaction_tracer :for_global,
  #                        :name => 'for_global',
  #                        :category => "Trade/for_global"
end
