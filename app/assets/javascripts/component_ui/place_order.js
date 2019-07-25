(function() {
    this.PlaceOrderUI = flight.component(function() {
        this.attributes({
            formSel: 'form',
            successSel: '.status-success',
            infoSel: '.status-info',
            dangerSel: '.status-danger',
            priceAlertSel: '.hint-price-disadvantage',
            positionsLabelSel: '.hint-positions',
            arrowDiv: '.arrow',
            feelabel: 'span.fee',
            amountFee: '.of-qty.fee',
            priceSel: 'input[id$=price]',
            volumeSel: 'input[id$=volume]',
            totalSel: 'input[id$=total]',
            currentBalanceSel: 'span.current-balance',
            submitButton: ':submit'
        });

        this.panelType = function() {
            switch (this.$node.attr('id')) {
                case 'bid_entry':
                    return 'bid';
                case 'ask_entry':
                    return 'ask';
            }
        };
        this.cleanMsg = function() {
            $('.status-success').fadeOut().text('');
            $('.status-info').fadeOut().text('');
            return $('.status-success').fadeOut().text('');
        };
        this.resetForm = function(event) {

            this.trigger('place_order::reset::price');
            this.trigger('place_order::reset::volume');
            this.trigger('place_order::reset::total');
            this.trigger('place_order::input::volume', {volume: null });
            this.trigger('place_order::input::total', {total: null });

            return this.priceAlertHide();
        };
        this.disableSubmit = function() {
            this.button_text = this.select('submitButton').text();
            return this.select('submitButton').addClass('disabled').attr('disabled', 'disabled');
        };
        this.enableSubmit = function() {
            this.select('submitButton').removeClass('disabled').removeAttr('disabled');
            this.select('submitButton').html(this.button_text);

            return this.cleanMsg;
        };
        this.confirmDialogMsg = function() {
            var confirmType, price, sum, volume;
            confirmType = this.select('submitButton').text();
            price = this.select('priceSel').val();
            volume = this.select('volumeSel').val();
            sum = this.select('totalSel').val();
            return "" + gon.i18n.place_order.confirm_submit + " \"" + confirmType + "\"?\n\n" + gon.i18n.place_order.price + ": " + price + "\n" + gon.i18n.place_order.volume + ": " + volume + "\n" + gon.i18n.place_order.sum + ": " + sum;
        };
        this.beforeSend = function(event, jqXHR) {
            if (true) {
                return this.disableSubmit();
            } else {
                return jqXHR.abort();
            }
        };
        this.handleSuccess = function(event, data) {

            this.select('successSel').append(JST["templates/hint_order_success"]({
                msg: data.message
            })).show();

            this.select('successSel').append(JST["templates/hint_order_success"]({
                msg: data.message
            })).wait(6000).hide(2000);

            this.resetForm(event);
            window.sfx_success();
            return this.enableSubmit();
        };
        this.handleError = function(event, data) {
            var ef_class, json;

            console.log('teste');

            ef_class = 'shake shake-constant hover-stop';
            json = JSON.parse(data.responseText);
            this.select('dangerSel').append(JST["templates/hint_order_warning"]({
                msg: json.message
            })).show().addClass(ef_class).wait(500).removeClass(ef_class);

            this.select('dangerSel').append(JST["templates/hint_order_warning"]({
                msg: json.message
            })).wait(6000).hide(2000);

            window.sfx_warning();
            return this.enableSubmit();
        };
        this.getBalance = function() {
            return BigNumber(this.select('currentBalanceSel').data('balance'));
        };
        this.getLastPrice = function() {
            return BigNumber(gon.ticker.last);
        };
        this.allIn = function(event) {
            switch (this.panelType()) {
                case 'ask':
                    this.trigger('place_order::input::price', {
                        price: this.getLastPrice()
                    });
                    return this.trigger('place_order::input::volume', {
                        volume: this.getBalance()
                    });
                case 'bid':
                    this.trigger('place_order::input::price', {
                        price: this.getLastPrice()
                    });
                    return this.trigger('place_order::input::total', {
                        total: this.getBalance()
                    });
            }
        };
        this.refreshBalance = function(event, data) {
            var balance, currency, fee, type, _ref;
            type = this.panelType();
            currency = gon.market[type].currency;
            balance = ((_ref = gon.accounts[currency]) != null ? _ref.balance : void 0) || 0;
            fee = gon.market[type].fee;
            this.select('currentBalanceSel').data('balance', balance);
            this.select('currentBalanceSel').text(formatter.fix(balance));
            this.select('feelabel').data('fee', fee);
            this.select('feelabel').text(formatter.fix(type, fee));
            this.trigger('place_order::balance::change', {
                balance: formatter.fix(balance)
            });
            return this.trigger("place_order::max::" + this.usedInput, {
                max: formatter.fix(balance)
            });
        };
        this.updateAvailable = function(event, order) {
            var available, balance, currency, node, type, _ref;
            type = this.panelType();
            node = this.select('currentBalanceSel');
            currency = gon.market[type].currency;
            balance = ((_ref = gon.accounts[currency]) != null ? _ref.balance : void 0) || 0;
            if (!order[this.usedInput]) {
                order[this.usedInput] = 0;
            }
            available = formatter.fix(type, this.getBalance().minus(order[this.usedInput]));
            if (BigNumber(balance) <= 0) {
                return this.disableSubmit();
            } else {
                this.enableSubmit();
                if (BigNumber(available).equals(0)) {
                    this.select('positionsLabelSel').hide().text(gon.i18n.place_order["full_" + type]).fadeIn();
                } else {
                    this.select('positionsLabelSel').fadeOut().text('');
                }
                return node.text(available);
            }
        };
        // this.updateAvailable = function(event, order) {
        //     var available, node, type;
        //     type = this.panelType();
        //     node = this.select('currentBalanceSel');
        //     if (!order[this.usedInput]) {
        //         order[this.usedInput] = 0;
        //     }
        //     available = formatter.fix(type, this.getBalance().minus(order[this.usedInput]));
        //     if (BigNumber(available).equals(0)) {
        //         this.select('positionsLabelSel').hide().text(gon.i18n.place_order["full_" + type]).fadeIn();
        //     } else {
        //         this.select('positionsLabelSel').fadeOut().text('');
        //     }
        //     return node.text(available);
        // };
        this.priceAlertHide = function(event) {
            return this.select('priceAlertSel').fadeOut(function() {

                return $(this).text('');
            });
        };
        this.priceAlertShow = function(event, data) {
            return this.select('priceAlertSel').hide().text(gon.i18n.place_order[data.label]).fadeIn();
        };
        this.clear = function(e) {
            this.resetForm(e);

            return this.trigger('place_order::focus::price');
        };
        return this.after('initialize', function() {


            var type;
            type = this.panelType();
            if (type === 'ask') {
                this.usedInput = 'volume';
            } else {
                this.usedInput = 'total';
            }
            PlaceOrderData.attachTo(this.$node);
            OrderPriceUI.attachTo(this.select('priceSel'), {
                form: this.$node,
                type: type
            });
            OrderVolumeUI.attachTo(this.select('volumeSel'), {
                form: this.$node,
                type: type
            });
            OrderTotalUI.attachTo(this.select('totalSel'), {
                form: this.$node,
                type: type
            });
            this.on('place_order::price_alert::hide', this.priceAlertHide);
            this.on('place_order::price_alert::show', this.priceAlertShow);
            this.on('place_order::order::updated', this.updateAvailable);
            this.on('place_order::clear', this.clear);
            this.on(document, 'account::update', this.refreshBalance);
            this.on(this.select('formSel'), 'ajax:beforeSend', this.beforeSend);
            this.on(this.select('formSel'), 'ajax:success', this.handleSuccess);
            return this.on(this.select('formSel'), 'ajax:error', this.handleError);
        });



    });

}).call(this);
