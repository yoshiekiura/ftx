(function() {
    this.OrderInputMixin = function() {
        this.attributes({
            form: null,
            type: null
        });
        this.reset = function() {
            this.text = '';
            return this.value = null;

        };
        this.rollback = function() {
            return this.$node.val(this.text);
        };
        this.parseText = function() {
            var text, value;
            text = this.$node.val();
            value = BigNumber(text);
            
            try {
                switch (false) {
                    case text !== this.text:
                        return false;
                    case text !== '':
                        this.reset();
                        this.trigger('place_order::reset', {
                            variables: this.attr.variables
                        });
                        return false;
                    case !!$.isNumeric(text):
                        this.rollback();
                        return false;
                    case !((text.split(".")[1].length) > this.attr.precision):
                        this.rollback();
                        return false;
                    default:
                        this.text = text;
                        this.value = value;
                        return true;
                }
            }catch(err){
                this.text = text;
                this.value = value;
                return true;
            }
        };
        this.roundValueToText = function(v) {

             if(v !== null){
                var y = v;
                y = BigNumber((String(y).indexOf('.') !== -1) ? y.toFixed(this.attr.precision) : y.toFixed(this.attr.precision) );

                return BigNumber(y).toFixed(this.attr.precision);

             }
            
             return BigNumber(0).toFixed(this.attr.precision);

        };
       

        this.roundNumberV1 = function(num, scale) {

            if(!("" + num).includes("e")) {
                return +(Math.round(num + "e+" + scale)  + "e-" + scale);
            } else {
                var arr = ("" + num).split("e");
                var sig = ""
                if(+arr[1] + scale > 0) {
                    sig = "+";
                }
                var i = +arr[0] + "e" + sig + (+arr[1] + scale);
                var j = Math.round(i);
                var k = +(j + "e-" + scale);

                return k;
            }
        };


        this.setInputValue = function(v) {

            if (v != null) {
                this.text = this.roundValueToText(v);

            } else {
                this.text = '';
            }
            return this.$node.val(this.text);
        };
        this.changeOrder = function(v) {

            return this.trigger('place_order::input', {
                variables: this.attr.variables,
                value: v
            });
        };
        this.process = function(event) {
             if (!this.parseText()) {
                 return;
             }
             if (this.validateRange(this.value)) {
                 return this.changeOrder(this.value);
                } else {
                return this.setInputValue(this.value);
             }
        };
        this.validateRange = function(v) {
            if (this.max && v.greaterThan(this.max)) {

                this.value = this.max;
                this.changeOrder(this.max);
                return false;
            } else if (v.lessThan(0)) {

                this.value = null;
                return false;
            } else {

                this.value = v;
                return true;
            }
        };
        this.onInput = function(e, data) {
            this.$node.val(data[this.attr.variables.input]);
            return this.process();
        };
        this.onMax = function(e, data) {
            return this.max = data.max;
        };
        this.onReset = function(e) {
            this.$node.val('');
            return this.reset();
        };
        this.onFocus = function(e) {
            return this.$node.focus();
        };
        return this.after('initialize', function() {
            this.orderType = this.attr.type;
            this.text = '';
            this.value = null;
            this.on(this.$node, 'change paste keyup', this.process);
            this.on(this.attr.form, "place_order::max::" + this.attr.variables.input, this.onMax);
            this.on(this.attr.form, "place_order::input::" + this.attr.variables.input, this.onInput);
            this.on(this.attr.form, "place_order::output::" + this.attr.variables.input, this.onOutput);
            this.on(this.attr.form, "place_order::reset::" + this.attr.variables.input, this.onReset);
            return this.on(this.attr.form, "place_order::focus::" + this.attr.variables.input, this.onFocus);
        });
    };

}).call(this);
