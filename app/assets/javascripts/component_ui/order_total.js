(function() {
    this.OrderTotalUI = flight.component(function() {
        flight.compose.mixin(this, [OrderInputMixin]);
        this.attributes({
            precision: gon.market.bid.fixed,
            variables: {
                input: 'total',
                known: 'price',
                output: 'volume'
            }
        });
        return this.onOutput = function(event, order) {
            var total;
            total = order.price.times(order.volume);
            if (!this.validateRange(total)) {
                this.changeOrder(this.value);
            }
            this.setInputValue(this.roundNumberV1(this.value, 2));
            // order.total = this.roundNumberV1(this.value, 2);
            return this.trigger('place_order::order::updated', order);
        };
    });

}).call(this);