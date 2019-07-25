(function () {
    app.controller('DepositBankController', function($scope, $stateParams, $http) {
        var ctrl, limit_rows;
        ctrl = this;

        limit_rows = 3;
        $scope.predicate = '-id';
        this.currency = $stateParams.currency;
        this.account = Account.findBy('currency', this.currency);
        this.deposits = this.account.deposits().slice(0, limit_rows);

        this.change_tab = function(event, tab_id) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace("active", "");
            }
            document.getElementById(tab_id).style.display = "block";
            event.currentTarget.className += " active";

            return true;
        };

        this.refresh = function( ) {
            $scope.$apply()
        };

        return (this.event = function() {
            return Deposit.bind("create update destroy", function() {
                return ctrl.refresh();
            });
        })();
    });
}).call(this);
