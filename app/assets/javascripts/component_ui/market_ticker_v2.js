(function() {
    window.MarketV2TickerUI = flight.component(function() {
        this.attributes({
            askSelector: '.ask.of-qty.price-value',
            bidSelector: '.bid.of-qty.price-value',
            balanceSelector: '.balance.of-qty',
            inOrdersSelector: '.order.of-qty',
            availableSelector: '.aval.of-qty'

        });
        this.panelType = function() {

            switch (this.$node.attr('id')) {
                case 'bid_entry':
                    return 'bid';
                case 'ask_entry':
                    return 'ask';
            }
        };
        this.updatePrice = function(selector, price, trend) {
            selector.removeClass('text-up').removeClass('text-down').addClass(formatter.trend(trend));
            return selector.html((price));
        };
        this.updateField = function(selector, value) {

            return selector.html(value);
        };
        this.refresh = function(event, ticker) {
            var marketId = ticker.base_unit + ticker.quote_unit;
            marketRoot = $('tbody').find("tr[data-market=" + marketId + "]");


            this.updateField(marketRoot.find("td[class=last]"),ticker.last);

            this.updateField(marketRoot.find("td[class=vol]"),ticker.volume);

            if (ticker.buy_trend != ticker.sell_trend && this.last_percent != ticker.last_24_percentage) {
                this.last_percent = ticker.last_24_percentage;
            }

            if (this.last_ticker_value[marketId]) {

                if(ticker.last > this.last_ticker_value[marketId]){
                    marketRoot.addClass('bought');
                }else if(ticker.last < this.last_ticker_value[marketId]){
                    marketRoot.addClass('sold');
                }else{

                }
                this.last_ticker_value[marketId] = ticker.last;
            }else{
                this.last_ticker_value[marketId] = ticker.last;
            }

            marketRoot.wait(1000).removeClass('sold').removeClass('bought');

            marketRoot.find("td[id=last_24]").removeClass('positive').removeClass('negative');

            if ( ticker.last_24_percentage > 0 ) {
                if ( ( ticker.open < ticker.buy ) || ( ticker.open < ticker.sell ) )  {
                    marketRoot.find("td[id=last_24]").addClass('positive');
                    this.updateField(marketRoot.find("td[id=last_24]"),"+"+ticker.last_24_percentage + '%');

                } else {
                    if ( ( ticker.open > ticker.buy ) || ( ticker.open > ticker.sell ) )  {
                        marketRoot.find("td[id=last_24]").addClass('negative');
                        this.updateField(marketRoot.find("td[id=last_24]"),"-"+ticker.last_24_percentage + '%');

                    }
                }
            }else{
                this.updateField(marketRoot.find("td[id=last_24]"),ticker.last_24_percentage + '%');

                marketRoot.find("td[id=last_24]").removeClass('negative');
                marketRoot.find("td[id=last_24]").removeClass('positive');
            }


            type = this.panelType();
            currency = gon.market[type].currency;

            if (marketId == gon.market.id && gon.accounts[currency] != null){
                marketRoot.addClass('active');

                var aval, balance, currency, locked, type;
                type = this.panelType();
                currency = gon.market[type].currency;
                // currency = ticker.base_unit;
                aval     = gon.accounts[currency].balance;
                locked   = gon.accounts[currency].locked;
                balance  = Number(new BigNumber(aval).plus(locked));

                this.updateField(this.select('askSelector'), parseFloat(ticker.sell).toFixed(2), ticker.sell_trend);
                this.updateField(this.select('bidSelector'), parseFloat(ticker.buy).toFixed(2), ticker.buy_trend);

                if(ticker.sell_trend) {
                    $('#order_ask_last_ask').val(parseFloat(ticker.buy).toFixed(2));
                    $("#order_ask_volume_holder").val(ticker.volume);
                }

                if(ticker.buy_trend) {
                    $('#order_bid_last_bid').val(parseFloat(ticker.sell).toFixed(2));
                    $("#order_bid_volume_holder").val(ticker.volume);

                }

                if (this.panelType() === 'bid') {

                    this.updateField(this.select('balanceSelector'), parseFloat(balance).toFixed(2));
                    this.updateField(this.select('inOrdersSelector'), parseFloat(locked).toFixed(2));
                    return this.updateField(this.select('availableSelector'), parseFloat(aval).toFixed(2));
                } else {

                    fixed = gon.markets[marketId].base_fixed;
                    this.updateField(this.select('availableSelector'), parseFloat(aval).toFixed(fixed));
                    this.updateField(this.select('balanceSelector'), parseFloat(balance).toFixed(fixed));
                    return this.updateField(this.select('inOrdersSelector'), parseFloat(locked).toFixed(fixed));
                }

            }

        };
        return this.after('initialize', function() {
            this.last_percent = 0;
            this.last_ticker_value = {};
            this.on(document, 'account::update', this.refresh);
            this.on(document, 'market::ticker', this.refresh);
            this.on(document, 'market::order-form-buy', this.refresh);
            return this.on(document, 'market::order-form-sell', this.refresh);
        });
    });

}).call(this);
