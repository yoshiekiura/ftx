(function () {
    app.controller('DepositTxidInformedController', [
        '$scope','$sce', '$stateParams', '$http', '$filter', 'ngDialog', function ($scope, $sce, $stateParams, $http, $filter, ngDialog) {



            $scope.myFunc = function () {

                $http.post("/deposits/deposit_txids",{
                    txid: $scope.txid_by_user,
                    currency: $stateParams.currency
                })
                    .success(function(data) {

                        $('.btn-orange').tooltip()
                            .attr('data-toggle', 'tooltip')
                            .attr('data-original-title' , data.msg)
                            .tooltip({
                                trigger: 'manual'
                            })
                            .tooltip('show');

                        if(data.status == 200) {
                            console.log('teste ok');
                            $('.btn-orange + .tooltip > .tooltip-inner').css(
                                "background-color", "#518E79",
                                "border-radius", "0px"
                            );

                            $('.btn-orange + .tooltip > .tooltip-arrow').css(
                                "border-right-color","#518E79"
                            );
                        }

                        if(data.status == 400){
                            console.log('teste erro'+ data.inspect );
                            $('.btn-orange + .tooltip > .tooltip-inner').css(
                                "background-color","#A85A5A",
                                "border-radius", "0px"
                            );

                            $('.btn-orange + .tooltip > .tooltip-arrow').css(
                                "border-right-color","#A85A5A"
                            );

                        }

                        hideTooltip($('.btn-orange'));
                    })

                // ngDialog.close();

                // var deposit_identification  = $scope.ngDialogData.deposit_identification;

                // var dialogWarning = ngDialog.open({
                //     template: '/templates/fund_sources/deposit_warning.html',
                //     controller: 'DepositWarningController',
                //     className: 'ngdialog-theme-default custom-width-modal1',
                //     showClose: false,
                //     data: {
                //         deposit_identification: deposit_identification
                //     }
                // });
                // return dialogWarning;

            }
    }

    ]);
}).call(this);
