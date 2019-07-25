$(window).load ->

  # clipboard
  $.subscribe 'deposit_address:create', (event, data) ->
    $('[data-clipboard-text], [data-clipboard-target]').each ->
      zero = new ZeroClipboard $(@), forceHandCursor: true

      zero.on 'complete', ->
        $(zero.htmlBridge)
          .attr('title', gon.clipboard.done)
          .tooltip('fixTitle')
          .tooltip('show')
      zero.on 'mouseout', ->
        $(zero.htmlBridge)
          .attr('title', gon.clipboard.click)
          .tooltip('fixTitle')

      placement = $(@).data('placement') || 'bottom'
      $(zero.htmlBridge).tooltip({title: gon.clipboard.click, placement: placement})

  # qrcode
  $.subscribe 'deposit_address:create', (event, data) ->

    code = if data then data else $('#deposit_address').html()
#    try
#      console.log('saida =' + code);
#
#      bchCrop = code.split ":"
#      console.log('saida 2=' + bchCrop[0]);
#      if bchCrop[0] == 'bitcoincash'
#        code = bchCrop[1]
#    catch e then
#
#    finally

    $("#qrcode-"+code).attr('data-text', code)
    $("#qrcode-"+code).attr('title', code)
    $("#qrcode-"+code+".qrcode-container").each (index, el) ->
      $el = $(el)
      $("#qrcode-"+code+" img").remove()
      $("#qrcode-"+code+" canvas").remove()
#      try
#        console.log('saida 3=' + bchCrop[0]);
#        if bchCrop[0] == 'bitcoincash'
#          code =  bchCrop[1]
#          console.log('saida 4=' + code);
#      catch e then
#
#      finally

      new QRCode el,
        text:   code
        width:  $el.data('width')
        height: $el.data('height')

  $.publish 'deposit_address:create'

  # flash message
  $.subscribe 'flash', (event, data) ->
    $('.flash-messages').show()
    $('.flash-content').html(data.message)
    setTimeout(->
      $('.flash-messages').hide(1000)
    , 10000)

  $.subscribe 'flash-success', (event, data) ->
    $('.flash-messages-success').show()
    $('.flash-content-success').html(data.message)
    setTimeout(->
      $('.flash-messages-success').hide(1000)
    , 10000)

  # init the two factor auth
  $.subscribe 'two_factor_init', (event, data) ->
    TwoFactorAuth.attachTo('.two-factor-auth-container')

  $.publish 'two_factor_init'
