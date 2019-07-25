(function() {
  var pusher;

  pusher = new Pusher(gon.pusher.key, {
    encrypted: gon.pusher.encrypted,
    cluster: gon.pusher.cluster
  });

  window.pusher = pusher;

}).call(this);