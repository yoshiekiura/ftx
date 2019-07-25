function copyToClipBoard(idElement, btn) {
    var copyText = document.getElementById(idElement);

    var el = document.createElement("textarea");
    el.value = copyText.value;
    document.body.appendChild(el);
    el.select();
    document.execCommand("copy");
    document.body.removeChild(el);

    tooltipFeedback(btn);

}

function copyToClipBoardHtml(idElement) {
    var copyText = document.getElementById(idElement).innerHTML;
    var el = document.createElement("textarea");
    el.value = copyText;
    document.body.appendChild(el);
    el.select();
    document.execCommand("copy");
    document.body.removeChild(el);
}

function copyToClipBoardHtml_BCH(idElement, btn) {
    var copyText = document.getElementById(idElement).innerHTML;

    var el = document.createElement("textarea");
    el.value = 'bitcoincash:'+copyText;
    document.body.appendChild(el);
    el.select();
    document.execCommand("copy");
    document.body.removeChild(el);

    tooltipFeedback(btn);

}

 function tooltipFeedback(btn) {
     $(btn).tooltip().attr('data-toggle', 'tooltip')
         .attr('data-original-title' , I18n.t('fund_sources.copied')
         )
         .tooltip({
             trigger: 'manual'
         })
         .tooltip('show');
     hideTooltip(btn);
}

function hideTooltip(btn) {
    setTimeout(function() {
        $(btn).removeAttr('data-toggle', 'tooltip')
            .removeAttr('data-original-title' , I18n.t('fund_sources.copied')
            )
            .tooltip('hide');
    }, 5000);
}



