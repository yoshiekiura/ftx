(function() {
    app.controller('WithdrawsController', [
        '$scope','$sce', '$rootScope', '$stateParams', '$http', '$filter', '$gon', 'fundSourceService', 'ngDialog', function($scope, $sce, $rootScope, $stateParams, $http, $filter, $gon, fundSourceService, ngDialog) {
            var currency, current_user, defaultFundSource, fund_sources, _selectedFundSourceId, _selectedFundSourceIdInList;
            if ($stateParams.currency === void 0) {
                $scope.currency = currency = 'brl';
            } else {
                $scope.currency = currency = $stateParams.currency;
            }
            $scope.current_user = current_user = $gon.current_user;
            $scope.name = current_user.name;
            $scope.account = Account.findBy('currency', $scope.currency);
            $scope.balance = $scope.account.balance;
            $scope.locked = $scope.account.locked;
            $scope.withdraw_channel = WithdrawChannel.findBy('currency', $scope.currency);
            $rootScope.curr = currency;
            _selectedFundSourceId = null;

            $scope.calculateTotal = function () {
                total =  parseFloat($scope.balance) +  parseFloat($scope.locked);
                return total;
            }

            if (gon.fees_withdraws[currency]) {
                $scope.fee_withdraw = currency.toUpperCase() + " " + gon.fees_withdraws[currency].fee;
                $scope.min_withdraw = gon.fees_withdraws[currency].fee * 2;
            }


            _selectedFundSourceIdInList = function(list) {
                var fs, _i, _len;
                for (_i = 0, _len = list.length; _i < _len; _i++) {
                    fs = list[_i];
                    if (fs.id === _selectedFundSourceId) {
                        return true;
                    }
                }
                return false;
            };

            $scope.changeToFiat = function() {
                return $scope.currency = currency = 'brl';
            };
            $scope.selected_fund_source_id = function(newId) {
                if (angular.isDefined(newId)) {
                    return _selectedFundSourceId = newId;
                } else {
                    return _selectedFundSourceId;
                }
            };
            $scope.fund_sources = function() {
                var fund_sources;
                fund_sources = fundSourceService.filterBy({
                    currency: currency
                });
                if (!_selectedFundSourceId || !_selectedFundSourceIdInList(fund_sources)) {
                    if (fund_sources.length) {
                        $scope.selected_fund_source_id(fund_sources[0].id);
                    }
                }
                return fund_sources;
            };
            defaultFundSource = fundSourceService.defaultFundSource({
                currency: currency
            });
            if (defaultFundSource) {
                _selectedFundSourceId = defaultFundSource.id;
            } else {
                fund_sources = $scope.fund_sources();
                if (fund_sources.length) {
                    _selectedFundSourceId = fund_sources[0].id;
                }
            }
            $scope.$watch(function() {
                $scope.changeFieldsFundSources();
                return fundSourceService.defaultFundSource({
                    currency: currency
                });
            }, function(defaultFundSource) {
                if (defaultFundSource) {
                    return $scope.selected_fund_source_id(defaultFundSource.id);
                }
            });
            $scope.changeFieldsFundSources = function() {
                var ex, fund_s, fund_select;
                fund_s = $scope.fund_sources();
                fund_select = $filter('filter')(fund_s, {
                    'id': _selectedFundSourceId
                });

                $scope.bank_code = null;

                $scope.agency = null;

                $scope.bank_account = null;

                $scope.bank_account_dig = null;

                $scope.cpf_cnpj = null;

                if(new Date().toLocaleTimeString("pt-BR") <= "16:30:00"){
                    $scope.normalTime= true;
                    $scope.unormalTime= false;

                }else{
                    $scope.normalTime= false;
                    $scope.unormalTime= true;

                }


                if (_selectedFundSourceId === null) {
                    $scope.bank_code = null;
                    $scope.agency = null;
                    $scope.bank_account = null;
                    $scope.bank_account_dig = null;
                    $scope.cpf_cnpj = null;
                }

                try {
                    $scope.bank_code = I18n.t("banks." + fund_select[0].extra);
                    $scope.agency = fund_select[0].agency;
                    $scope.bank_account = fund_select[0].account;
                    $scope.bank_account_dig = fund_select[0].accountDigit;
                    $scope.cpf_cnpj = fund_select[0].cpf;
                    if (fund_select[0].extra === '_341') {
                        $scope.type_transfer = I18n.t('fund_sources.type_transfer') + ': TEF';
                    } else {
                        $scope.type_transfer = I18n.t('fund_sources.type_transfer') + ': TED';
                    }
                } catch (_error) {
                    ex = _error;
                }
            };
            $scope.changeFieldsFundSources();
            this.withdraw = {};
            this.createWithdraw = function(currency) {
                var account, data, otp, text_button, type, withdraw_channel;
                withdraw_channel = WithdrawChannel.findBy('currency', currency);
                account = withdraw_channel.account();
                data = {
                    withdraw: {
                        member_id: current_user.id,
                        currency: currency,
                        sum: this.withdraw.sum,
                        fund_source_id: _selectedFundSourceId
                    }
                };

                if (current_user.app_activated || current_user.sms_activated) {
                    type = $('.two_factor_auth_type').val();
                    otp = this.two_factor_otp;
                    data.two_factor = {
                        type: type,
                        otp: otp
                    };
                    data.g_recaptcha_response = $scope.getKeyRecaptcha();
                }
                $('.form-submit > button').attr('disabled', 'disabled');
                text_button = $('.form-submit > button').html();
                $('.form-submit > button').html('<i class=\'fa fa-spinner fa-spin\'></i>');
                return $http.post("/withdraws/" + withdraw_channel.resource_name, data).success(function(data, status, header, config) {
                    return $.publish('flash-success', {
                        message: I18n.t('funds.withdraw_brl.message_success')
                    });
                }).error(function(responseText) {
                    $.publish('flash', {
                        message: responseText
                    });
                    return $scope.checkRecaptcha();
                })["finally"]((function(_this) {
                    return function() {
                        _this.withdraw = {};
                        $scope.balance = $scope.account.balance;
                        $(".two_factor_otp").val("");
                        $('.form-submit > button').html(text_button);
                        return $('.form-submit > button').removeAttr('disabled');
                    };
                })(this));
            };
            this.withdrawAll = function() {
                return this.withdraw.sum = Number($scope.account.balance);
            };
            this.withdrawAllCoin = function() {
                return this.withdraw.sum = Number($scope.account.balance);
            };
            $scope.openFundSourceManagerPanel = function() {
                var className, template;
                if ($scope.currency === $gon.fiat_currency) {
                    template = '/templates/fund_sources/bank.html';
                    className = 'ngdialog-theme-default custom-width coin';
                } else {
                    template = '/templates/fund_sources/coin.html';
                    className = 'ngdialog-theme-default custom-width coin';

                }
                return ngDialog.open({
                    template: template,
                    controller: 'FundSourcesController',
                    className: className,
                    data: {
                        currency: $scope.currency
                    }
                });
            };

            $scope.openFundSourceManagerPanelFiat = function() {
                var className, template;

                template = '/templates/fund_sources/bank.html';
                className = 'ngdialog-theme-default custom-width coin';

                return ngDialog.open({
                    template: template,
                    controller: 'FundSourcesController',
                    className: className,
                    data: {
                        currency: $scope.currency
                    }
                });
            };


            $scope.openFundSourceManagerPanelW = function() {
                return ngDialog.open({
                    template: '/templates/fund_sources/coin.html',
                    controller: 'FundSourcesController',
                    className: 'ngdialog-theme-default custom-width',
                    data: {
                        currency: $scope.currency
                    }
                });
            };

            $scope.sms_and_app_activated = function() {
                return current_user.app_activated && current_user.sms_activated;
            };
            $scope.only_app_activated = function() {
                return current_user.app_activated && !current_user.sms_activated;
            };
            $scope.only_sms_activated = function() {
                return current_user.sms_activated && !current_user.app_activated;
            };
            $scope.checkRecaptcha = function() {
                $http({
                    method: 'GET',
                    url: '/two_factors/app'
                }).then(function successCallback(response) {

                }, function errorCallback(response) {
                    $('.captcha-wrap').html(response.data);
                });
            };

            $scope.getKeyRecaptcha = function (){
                var key = '';
                $(".g-recaptcha-response").each(function() {
                    if($(this).val()){
                        key = $(this).val();

                    }
                });
                return key;

            };

            return $scope.$watch((function() {
                return $scope.currency;
            }), function() {
                return setTimeout(function() {
                    $.publish("two_factor_init");
                    return 30000;
                });
            });


        }
    ]);

}).call(this);