(function () {
    app.controller('DepositBankConfirmationController', [
        '$scope','$sce', '$stateParams', '$http', '$filter', 'ngDialog', function ($scope, $sce, $stateParams, $http, $filter, ngDialog) {

            var created_at = $scope.ngDialogData.created_at;
            var expire = new Date(created_at);

            expire.setDate(expire.getDate() + 2);

            var data_init = new Date(created_at);
            expire.setDate(expire.getDate() + 2);


            var fix_minutes = (expire.getMinutes()<10?'0':'') + expire.getMinutes();

            var time =  data_init.getHours()+':'+ fix_minutes;

            var date_expire_formated = expire.toLocaleDateString("pt-BR");

            var type = $scope.ngDialogData.deposit_type;

            var amount = $scope.ngDialogData.deposit_obj.amount;

            var type_transfer_description;

            switch(type) {
                case "TEF":
                    type_transfer_description =  I18n.t("funds.deposit_modal.tef");
                    break;
                case "TED":
                    type_transfer_description = I18n.t("funds.deposit_modal.ted");
                    break;
                case "DIA":
                    type_transfer_description = I18n.t("funds.deposit_modal.dia");
                    type = "TEF";
                    break;
            }

            var content =  I18n.t("funds.deposit_modal.content_header",{type_transfer_description: type_transfer_description, expire: date_expire_formated ,date_create: data_init.toLocaleDateString("pt-BR"), time_created: time  });
            content += I18n.t("funds.deposit_modal.content_" + type.toLowerCase(),{samurai_code: $scope.ngDialogData.deposit_identification, expire: date_expire_formated , valor_deposito: amount, date_create: data_init.toLocaleDateString("pt-BR"), time_created: time,date_create:data_init.toLocaleDateString("pt-BR"), time_created: time });
            content += I18n.t("funds.deposit_modal.content_footer_"+ type.toLowerCase());
            //console.log("SAIDA = "+ content);
            $scope.modal_content = $sce.trustAsHtml(content);




            $scope.cancelDeposit = function() {
                var deposit = $scope.ngDialogData.deposit_obj;
                var deposit_channel;
                deposit_channel = DepositChannel.findBy('currency', deposit.currency);
                return $http["delete"]("/deposits/" + deposit_channel.resource_name + "/" + deposit.id).error(function(responseText) {
                    return $.publish('flash', {
                        message: responseText
                    });
                })
                    .success(function(data, status, header, config) {
                        ngDialog.close();
                    });
            };

            $scope.submit = function() {
                var deposit = $scope.ngDialogData.deposit_obj;
                var deposit_channel;
                deposit_channel = DepositChannel.findBy('currency', deposit.currency);
                $http["put"]("/deposits/" + deposit_channel.resource_name + "/" + deposit.id)
                    .error(function(responseText) {
                        return $.publish('flash', {
                            message: responseText
                        });
                    });

                ngDialog.close();
                //var deposit_identification  = $scope.ngDialogData.deposit_identification;

               /* var dialogWarning = ngDialog.open({
                    template: '/templates/fund_sources/deposit_warning.html',
                    controller: 'DepositWarningController',
                    className: 'ngdialog-theme-default custom-width-modal1',
                    showClose: false,
                    data: {
                        deposit_identification: deposit_identification
                    }
                });
                return dialogWarning;*/

            };

            return $scope.$watch((function() {
            }), function() {
                return setTimeout(function() {
                }, 1000);
            });
        }

    ]);
}).call(this);
