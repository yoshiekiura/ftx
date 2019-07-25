(function() {
    app.controller('TabsController', [
        '$scope', '$rootScope','$window', function($scope, $rootScope, $window) {

            $scope.showBtnSubmit = function() {
                if(new Date().toLocaleTimeString("pt-BR") <= "16:30:00"){
                    $("#div_normal_time").show();
                    $("#div_unormal_time").hide();
                }else{
                    $("#div_unormal_time").show();
                    $("#div_normal_time").hide();
                }

            };


            $scope.showTransferForm = function() {


                $rootScope.dpTransfer = {
                    show  : true
                };

                $rootScope.dpSlip = {
                    show  : false
                };
            };

            $scope.showSlipForm = function() {
                $rootScope.dpTransfer = {
                    show  : false
                };

                $rootScope.dpSlip = {
                    show  : true
                };
            };

            $scope.changeLocationToDeposits = function() {

                $window.location.href = '#/deposits/';
                $window.location.reload();

            };

            $scope.changeLocationToWithdraws = function() {
                $window.location.href = '#/withdraws/';
                $window.location.reload();
            };

            var str_url = ($window.location.href);

            if(str_url.includes('deposit')){
                $scope.deposit = true;
                $scope.withdraw = false;
            }

            if(str_url.includes('withdraws')){
                $scope.deposit = false;
                $scope.withdraw = true;
            }
        }
    ]);

}).call(this);
