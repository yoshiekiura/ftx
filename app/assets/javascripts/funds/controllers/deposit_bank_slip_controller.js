(function () {
    app.controller('DepositBankSlipController', [
        '$scope', '$window', '$stateParams', '$http', '$filter', '$gon', 'ngDialog', function ($scope, $window, $stateParams, $http, $filter, $gon, ngDialog) {
            var current_user;
            $scope.deposit = {};
            $scope.deposit_slip = {};

            this.tax = gon.slips[gon.slip_system_method]['tax'];

            $scope.currency = $stateParams.currency;
            $scope.current_user = current_user = $gon.current_user;
            $scope.email = current_user.email;
            $scope.fund_sources = $gon.fund_sources;
            $scope.account = Account.findBy('currency', $scope.currency);
            $scope.deposit_channel = DepositChannel.findBy('currency', $scope.currency);

            $scope.calculate_tax = function() {

                if($scope.tax != undefined){
                var tax = parseFloat($scope.tax);
                }else{
                    var tax = 0;
                }
                var valueAmount = $scope.deposit.amount.replace(',','.');
                var amount = parseFloat( valueAmount.replace('R$ ','') );

                var sum = (amount + ((amount / 100) * tax )) + parseFloat(6.50);

                if (Number.isNaN(sum)) { sum = 0; }

                $scope.amount_sum = 'R$ ' + sum.toFixed(2);

            };

            $scope.fill_by_postal_code = function() {
                if ($scope.validate_postal_code() ){
                    var postal_code = $scope.deposit_slip.postal_code.replace('-','');
                    $.getJSON("https://viacep.com.br/ws/"+ postal_code +"/json/?callback=?", function(data) {
                        if (!("erro" in data)) {
                            $scope.deposit_slip.address_name = data.bairro + ' - ' + data.logradouro;
                            $scope.deposit_slip.state = data.uf;
                            $scope.deposit_slip.city = data.localidade;
                        }
                    });
                }
            };

            $scope.validate_postal_code = function() {
                var regex = /^[0-9]{8}$/;
                if ( $scope.deposit_slip.postal_code != null ) {
                    return regex.test($scope.deposit_slip.postal_code.replace('-',''));
                } else {
                    return false;
                }
            };

            $scope.validate_person_doc = function() {
                if ($scope.deposit_slip.person_doc == null) { return false; }

                var clean = ($scope.deposit_slip.person_doc).replace(/\D/g, '');
                if (!(clean.length == 11 || clean.length == 14)) { return false; }
                if (clean.length == 11) { return $scope.validate_person_doc_cpf(clean); }
                if (clean.length == 14) { return $scope.validate_person_doc_cnpj(clean); }
            };

            $scope.validate_person_doc_cpf = function(doc) {
                var c = doc.substr(0,9);
                var dv = doc.substr(9,2);
                var d1 = 0;
                for (var i=0; i<9; i++) { d1 += c.charAt(i)*(10-i); }
                if (d1 == 0) return false;
                d1 = 11 - (d1 % 11);
                if (d1 > 9) d1 = 0;
                if (dv.charAt(0) != d1){ return false; }
                d1 *= 2;
                for (var i = 0; i < 9; i++)	{ d1 += c.charAt(i)*(11-i); }
                d1 = 11 - (d1 % 11);
                if (d1 > 9) d1 = 0;
                if (dv.charAt(1) != d1){ return false; }
                return true;
            };
            $scope.validate_person_doc_cnpj = function(doc) {
                var a = new Array();
                var b = new Number;
                var c = [6,5,4,3,2,9,8,7,6,5,4,3,2];
                for (i=0; i<12; i++){
                    a[i] = doc.charAt(i);
                    b += a[i] * c[i+1];
                }
                if ((x = b % 11) < 2) { a[12] = 0 } else { a[12] = 11-x }
                b = 0;
                for (y=0; y<13; y++) { b += (a[y] * c[y]); }
                if ((x = b % 11) < 2) { a[13] = 0; } else { a[13] = 11-x; }
                if ((doc.charAt(12) != a[12]) || (doc.charAt(13) != a[13])){ return false; }
                return true;
            };
            
            this.validate_all = function() {
                // TODO: this is not the best approach. Must be refactored to use MODEL validation
                if ($scope.deposit.amount == null) { return false; }
                if ($scope.deposit_slip.person_name == null) { return false; }
                if ($scope.deposit_slip.person_doc == null) { return false; }
                if ($scope.deposit_slip.phone == null) { return false; }
                if ($scope.deposit_slip.city == null) { return false; }
                if ($scope.deposit_slip.state == null) { return false; }
                if ($scope.deposit_slip.address_number == null) { return false; }
                if ($scope.deposit_slip.address_name == null) { return false; }
                if ($scope.deposit_slip.postal_code == null) { return false; }
                if ($scope.validate_person_doc() == false) { return false; }
                return true;
            };

            this.sanitize_data = function() {
                var regex = /\s|[a-zA-Z_]|\W|[#$%^&*()]/g;
                $scope.deposit_slip.person_doc = $scope.deposit_slip.person_doc.replace(regex, "");
                $scope.deposit_slip.phone = $scope.deposit_slip.phone.replace(regex, "");
                $scope.deposit_slip.postal_code = $scope.deposit_slip.postal_code.replace(regex, "");
            };

            return this.createDeposit = function (currency) {
                var amount_slip = parseFloat( $scope.deposit.amount.replace('R$ ',''));
                if(amount_slip < 25){
                    $.publish('flash', { message: I18n.t("funds.deposit_brl.message_error_limit") });
                    
                    return;
                }

                if(currency == undefined){
                    currency = 'brl';
                }

                if ($scope.deposit.amount == null || $scope.deposit.amount <= 25 ) {
                    $.publish('flash', { message: I18n.t("funds.deposit_brl.message_error_limit") });
                    return false;
                }

                if( this.validate_all() ){
                    this.sanitize_data();

                    deposit_channel = DepositChannel.findBy('currency', currency);
                    account = deposit_channel.account();
                    model = gon.slips[gon.slip_system_method]['code'];

                    var valueAmount = $scope.deposit.amount.replace(',','.');
                    var amount = parseFloat( valueAmount.replace('R$ ','') );

                    data = {
                        account_id: account.id,
                        member_id: current_user.id,
                        currency: currency,
                        amount: amount,
                        fund_source: $scope.deposit.fund_source,
                        type: $scope.deposit.type,
                        slip: $scope.deposit_slip
                    };

                    $('.form-submit > input').attr('disabled', 'disabled');
                    var text_button = $('.form-submit > button').html();
                    $('.form-submit > button').html("<i class='fa fa-spinner fa-spin'></i>");

                    return $http.post("/deposits/slips/" + model, { deposit: data
                    }).success(function(data, status, header, config) {
                        $.publish('flash-success', {
                            message: data['message']
                        });

                        var win = $window.open(data.message, '_blank');
                        win.focus();
                        return;
                    })
                      .error(function(data, status, header, config) {
                        return $.publish('flash', {
                            message: data['message']
                        });

                      })["finally"](function() {
                        $scope.deposit = {};
                        $scope.deposit_slip = {};
                        $scope.amount_sum = "";
                        $('.form-submit > button').html(text_button);
                        return $('.form-submit > button').removeAttr('disabled');
                    });

                } else {
                    $.publish('flash', {
                        message: I18n.t("funds.deposit_brl.message_validation")
                    });

                    $('.form-submit > button').html(text_button);
                    return $('.form-submit > button').removeAttr('disabled');
                }
            };
        }
    ]);

}).call(this);
