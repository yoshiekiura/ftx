app.directive("myNumber", function() {
    return {
        restrict: "EA",
        template: "<input class=\"form-control\"\n" +
        "                     id=\"deposit_sum\" mask=\"R$ 9?9?9?9?9?9?9\"  placeholder=\"{{'payment_slip.label_amount' | t}}\"  name=\"deposit[sum]\"\n" +
        "                     ng-model=\"depositsCtrl.deposit.amount\" required>",
        replace: true,
        link: function(scope, e, attrs) {
            e.bind("keydown", function(e) {

                if ((e.keyCode >= 48 && e.keyCode <= 57) || (e.keyCode >= 96 && e.keyCode <= 105) || ([8, 13, 27, 37, 38, 39, 40].indexOf(e.keyCode) > -1)) {

                }else{
                    e.preventDefault();
                }

            });
        }
    };
});