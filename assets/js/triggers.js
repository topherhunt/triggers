import $ from "jquery"

$(function(){

  window.addResolveButtonListeners = function(){
    $('.js-resolve-trigger').off().click(function(e){
      e.preventDefault();
      let instance_id = $(this).data('instance-id');
      let status = $(this).data('status');

      $(this).replaceWith("<em>Saving...</em>");

      json_request("GET", "/triggers/"+instance_id+"/resolve", {
        data: {status: status},
        success: function(data){
          $('.js-upcoming-triggers-list').replaceWith(data.table_html);
          addResolveButtonListeners();
        },
        error: function(){
          alert("Unable to save your changes. Please refresh the page.");
        }
      });
    });
  };

  addResolveButtonListeners();

  if ($('.js-browser-nags').length > 0) {

    if (Notification.permission != 'granted') {
      $('.js-notifications-blocked').show();
    }

    $('.js-enable-notifications').click(function(e){
      e.preventDefault();
      Notification.requestPermission().then(function(){
        $('.js-notifications-blocked').fadeOut();
      });
    });

    window.showBrowserNotification = function(){
      if (!window.Notification) {
        $('.js-notifications-not-supported').show();
        return;
      }

      if (Notification.permission != 'granted') {
        $('.js-notifications-blocked').show();
        return;
      }

      json_request("GET", "/triggers/browser_nag", {
        success: function(data){
          $('.js-notifications-broken').hide();
          if (data.num_due > 0) {
            var title = "You have "+data.num_due+" due triggers!";
            var body = data.preview;
            // requireInteraction is broken on both Chrome and FF as of 2021-04.
            // See https://stackoverflow.com/q/67038441/1729692
            new Notification(title, {body: body});
            playMeow();
          }
        },
        error: function(){
          $('.js-notifications-broken').show();
        }
      });
    };

    window.setInterval(showBrowserNotification, 1000 * 60 * 3);

    function playMeow() {
      var n = Math.ceil(Math.random() * 3);
      var audio = new Audio("/sounds/nag"+n+".mp3");
      audio.volume = 0.2;
      audio.play();
    }
  }

});
