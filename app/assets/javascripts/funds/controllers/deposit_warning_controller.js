(function () {
    app.controller('DepositWarningController', [
        '$scope','$sce', '$stateParams', '$http', '$filter', 'ngDialog', function ($scope, $sce, $stateParams, $http, $filter, ngDialog) {

            var content = I18n.t("funds.deposit_modal.deposit_code") + ": " + $scope.ngDialogData.deposit_identification;
            var info = I18n.t("funds.deposit_brl.deposit_warning_information");

            $scope.modal_content = $sce.trustAsHtml(content);
            $scope.info = $sce.trustAsHtml(info);

            $scope.submit = function() {
                ngDialog.close();
            }

            return $scope.$watch((function() {
            }), function() {
                return setTimeout(function() {
                }, 1000);
            });
        }

    ]);
}).call(this);
