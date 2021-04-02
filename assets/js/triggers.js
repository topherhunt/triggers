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
      Notification.requestPermission();
    }

    window.showBrowserNotification = function(){
      if (!window.Notification) {
        alert("Your browser doesn't support desktop notifications.");
        return;
      }

      if (Notification.permission != 'granted') {
        alert("Please refresh the page and give permission to show notifications.");
        return;
      }

      json_request("GET", "/triggers/browser_nag", {
        success: function(data){
          if (data.num_due > 0) {
            new Notification("You have "+data.num_due+" due triggers!", {
              body: data.preview,
              // Disabling this for now because it breaks the notification on Chrome...?
              // requireInteraction: true
            });
          }
        },
        error: function(){
          alert("Error checking for due triggers. Please refresh the page.");
        }
      });
    };

    window.setInterval(showBrowserNotification, 1000 * 60 * 5);
  }

});
