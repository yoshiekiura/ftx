(function() {
    app.controller('DepositsController', [
        '$scope', '$rootScope', '$stateParams' ,'$http', '$filter', '$gon', 'fundSourceService', 'ngDialog', function($scope, $rootScope, $stateParams, $http, $filter, $gon, fundSourceService, ngDialog) {
            var current_user;
            var _selectedFundSourceId, _selectedFundSourceIdInList, defaultFundSource, fund_sources;
            this.deposit = {};

            $scope.currency = currency = $stateParams.currency;

            $scope.current_user = current_user = $gon.current_user;
            $scope.name = current_user.name;
            $scope.fund_sources = $gon.fund_sources;
            $scope.account = Account.findBy('currency', $scope.currency);
            $scope.deposit_channel = DepositChannel.findBy('currency', $scope.currency);

            $rootScope.curr = currency;

            _selectedFundSourceId = null;
            _selectedFundSourceIdInList = function(list) {
                var fs, i, len;
                for (i = 0, len = list.length; i < len; i++) {
                    fs = list[i];
                    if (fs.id === _selectedFundSourceId) {
                        return true;
                    }
                }
                return false;
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
                if($stateParams.currency != undefined){
                    $scope.currency = currency = 'brl';
                }else{
                $scope.currency = currency = $stateParams.currency;
                }

                return fundSourceService.defaultFundSource({
                    currency: currency
                });
            }, function(defaultFundSource) {
                if (defaultFundSource) {
                    return $scope.selected_fund_source_id(defaultFundSource.id);
                }
            });



            this.createDeposit = function(currency) {

                if(this.deposit.amount < 25){
                    $.publish('flash', {
                        message: I18n.t("funds.deposit_brl.message_error_limit")
                    });
                    return;

                }

                if($("#cpfcnpj").val() === ''){
                    $.publish('flash', {
                        message: I18n.t("funds.deposit_brl.message_validation")
                    });
                    return;

                }

                if(currency == undefined){
                    currency = 'brl';
                }

                var account, data, depositCtrl, deposit_channel;
                depositCtrl = this;
                deposit_channel = DepositChannel.findBy('currency', currency);

                account = Account.findBy('member_id', current_user.id);

                data = {
                    account_id: account.id,
                    member_id: current_user.id,
                    currency: currency,
                    amount: this.deposit.amount,
                    fund_source: _selectedFundSourceId,
                    type: this.deposit.type
                };

                $('.form-submit > button').attr('disabled', 'disabled');
                var text_button = $('.form-submit > button').html();
                $('.form-submit > button').html("<i class='fa fa-spinner fa-spin'></i>");


                    return $http.post("/deposits/" + deposit_channel.resource_name, {
                        deposit: data
                    })
                        .success(function(data, status, header, config) {
                            depositCtrl.deposit = {};
                            $scope.showModalConfirmationDeposit(data);
                        })
                        .error(function(responseText) {
                            depositCtrl.deposit = {};
                            $.publish('flash', {
                                message: responseText
                            });
                            return;

                        })["finally"](function() {
                        depositCtrl.deposit = {};
                        $('.form-submit > button').html(text_button);
                        return $('.form-submit > button').removeAttr('disabled');
                    });

            };

            $scope.changeFieldsFundSources = function() {
                
                var fund_s = $scope.fund_sources();
                var fund_select = $filter('filter')(fund_s, {'id':_selectedFundSourceId});

                $scope.bank_code = null;
                $scope.agency = null;
                $scope.bank_account = null;
                $scope.bank_account_dig = null;
                $scope.cpf_cnpj = null;

                if (_selectedFundSourceId == null){
                    $scope.bank_code = null;
                    $scope.agency = null;
                    $scope.bank_account = null;
                    $scope.bank_account_dig = null;
                    $scope.cpf_cnpj = null;
                }

                try{

                $scope.bank_code = I18n.t("banks."+fund_select[0].extra);
                $scope.agency = fund_select[0].agency;
                $scope.bank_account = fund_select[0].account;
                $scope.bank_account_dig = fund_select[0].accountDigit;
                $scope.cpf_cnpj = fund_select[0].cpf;

                if(fund_select[0].extra == "_341"){
                    $scope.type_transfer = I18n.t("fund_sources.type_deposit") + ": TEF";
                }else{
                    $scope.type_transfer = I18n.t("fund_sources.type_deposit") + ": TED";
                }
                }catch(ex){
                }

            };
            $scope.changeFieldsFundSources();

            $scope.openFundSourceManagerPanel = function() {
                return ngDialog.open({
                    template: '/templates/fund_sources/bank.html',
                    controller: 'FundSourcesController',
                    className: 'ngdialog-theme-default custom-width',
                    data: {
                        currency: $scope.currency
                    }
                });
            };



            $scope.genAddress = function(resource_name) {
                return ngDialog.openConfirm({
                    template: '/templates/shared/confirm_dialog.html',
                    data: {
                        content: $filter('t')('funds.deposit_coin.confirm_gen_new_address')
                    }
                }).then(function() {
                    $("a#new_address").html('...');
                    $("a#new_address").attr('disabled', 'disabled');
                    return $http.post("/deposits/" + resource_name + "/gen_address", {}).error(function(responseText) {
                        return ngDialog.openConfirm({
                            template: '/templates/shared/confirm_dialog.html',
                            data: {
                                content: responseText
                            }
                        }).then(function() {});

                    })["finally"](function() {
                        $("a#new_address").html(I18n.t("funds.deposit_coin.new_address"));
                        return $("a#new_address").attr('disabled', 'disabled');
                    });
                });
            };

            $scope.showModalConfirmationDeposit = function(response_deposit) {

                var temp = response_deposit.txid.split(':');
                var deposit_type = temp[0];
                var deposit_identification = deposit_type == "TED" ? temp[1] : temp[2];
                var created_at = response_deposit.created_at;
                var state = response_deposit.aasm_state;
                if(state != "rejected"){
                    if(deposit_identification != null){

                        return ngDialog.open({
                            template: '/templates/fund_sources/deposit_bank_confirmation.html',
                            controller: 'DepositBankConfirmationController',
                            className: 'ngdialog-theme-default custom-width-modal1',
                            showClose: false,
                            data: {
                                deposit_identification: deposit_identification,
                                deposit_type: deposit_type,
                                created_at: created_at,
                                deposit_obj: response_deposit
                            }
                        });
                    }else{
                        $.publish('flash', {
                            message: I18n.t("funds.deposit_brl.message_error")
                        });

                        return;
                    }
                }else{
                    $.publish('flash', {
                        message: I18n.t("funds.deposit_brl.message_rejected")
                    });
                    return;
                }
            };





            return $scope.$watch((function() {
                $scope.changeFieldsFundSources();

                try{

                if($scope.account.deposit_address !=null){
                    var adress = $scope.account.deposit_address;
                    adress = adress.split(':');

                    if(adress[1] !== undefined){
                        $scope.account.deposit_address = adress[1];
                    }else{
                        $scope.account.deposit_address = adress[0];
                    }
                }

                }catch(ex){
                    $scope.account={};
                    $scope.account.deposit_address={};
                    $scope.account.deposit_address = 0;
                }

                return $scope.account.deposit_address;
				
            }), function() {
                return setTimeout(function() {
                    return $.publish('deposit_address:create');
                }, 1000);
            });
        }
    ]);

}).call(this);
