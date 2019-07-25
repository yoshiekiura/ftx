(function() {
    this.BankSlipUtil = function(){
    document.getElementById("defaultOpen").click();

    function open_deposit(evt, tab_id) {
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
        evt.currentTarget.className += " active";
    }

    function validate_slip_data() {
        var name = brl_payment.name.value;
        var cpf_cpnj = brl_payment.cpf_cpnj.value;
        var address = brl_payment.address.value;
        var number = brl_payment.number.value;
        var cep = brl_payment.cep.value;
        var phone = brl_payment.phone.value;
        var uf = brl_payment.uf.value;
        var city = brl_payment.city.value;

        if (amount_val == "") { brl_payment.amount_val.focus(); return false; }
        if (name == "") {  brl_payment.name.focus(); return false; }
        if (cpf_cpnj == "") { brl_payment.cpf_cpnj.focus(); return false; }
        if (address == "") { brl_payment.address.focus(); return false;  }
        if (number == "") { brl_payment.number.focus(); return false; }
        if (cep == "") { brl_payment.cep.focus();  return false; }
        if (phone == "") { brl_payment.phone.focus(); return false; }
        if (uf == "") { brl_payment.uf.focus(); return false; }
        if (city == "") { brl_payment.city.focus(); return false; }
    }

    $(document).ready(function() {

        function clean_cep_form() {
            // Limpa valores do formulário de cep.
            $("#address").val("");
            $("#city").val("");
            $("#uf").val("");
        }

        //Quando o campo cep perde o foco.
        $("#cep").blur(function() {

            //Nova variável "cep" somente com dígitos.
            var cep = $(this).val().replace(/\D/g, '');

            //Verifica se campo cep possui valor informado.
            if (cep != "") {

                //Expressão regular para validar o CEP.
                var validacep = /^[0-9]{8}$/;

                //Valida o formato do CEP.
                if(validacep.test(cep)) {

                    //Preenche os campos com "..." enquanto consulta webservice.
                    $("#address").val("...");
                    $("#city").val("...");
                    $("#uf").val("...");


                    //Consulta o webservice viacep.com.br/
                    $.getJSON("https://viacep.com.br/ws/"+ cep +"/json/?callback=?", function(data) {

                        if (!("erro" in data)) {
                            //Atualiza os campos com os valores da consulta.
                            $("#address").val(data.logradouro);
                            $("#city").val(data.localidade);
                            $("#uf").val(data.uf);

                        } //end if.
                        else {
                            //CEP pesquisado não foi encontrado.
                            clean_cep_form();
                            alert("CEP não encontrado.");
                        }
                    });
                } //end if.
                else {
                    //cep é inválido.
                    clean_cep_form();
                    alert("Formato de CEP inválido.");
                }
            } //end if.
            else {
                //cep sem valor, limpa formulário.
                clean_cep_form();
            }
        });
    });
    $('#phone').mask('(00) 0 0000-0000');
    $('#amount_val').mask('#,##0.00', {reverse: true});

};
}).call(this);
