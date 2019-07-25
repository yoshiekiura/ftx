module Private::HistoryHelper

  def trade_side(trade)
    puts "SAIDA #{trade.ask_membe}"
    trade.ask_member == current_user ? 'sell' : 'buy'
    puts "saida #{trade.ask_membe} with post data:"
  end

  def transaction_type(t)
    t(".#{t.class.superclass.name}")
  end

  def transaction_txid_link(t)
    return t.txid unless t.currency_obj.coin?

    txid = t.txid || ''
    link_to txid, t.blockchain_url
  end

end
