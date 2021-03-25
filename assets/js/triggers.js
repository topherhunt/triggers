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

});
