import $ from "jquery"

$(function(){
  $('.js-toggle-target').click(function(e){
    e.preventDefault()
    let targetSelector = $(this).data('target')
    $(targetSelector).toggle(200)
  })


  $('.js-select2').each(function(){
    var prompt = $(this).find('option[value=""]').text() || '- select one -'

    $(this).select2({
      // theme: 'bootstrap4',
      allowClear: true,
      minimumResultsForSearch: 10,
      placeholder: prompt
    })

    // Add a placeholder to the search field
    $(this).on('select2:open', function(){
      $('.select2-search__field').attr('placeholder', 'Type to search...')
    })
  })
})

window.testError = function() {
  return someRandomFunctionName()
};

window.json_request = function(method, url, opts) {
  opts = opts || {};
  // See https://api.jquery.com/Jquery.ajax/
  $.ajax({
    method: method,
    url: url,
    data: opts.data || {},
    dataType: "json",
    success: function(data, status, xhr){
      console.log("Request "+method+" "+url+" success ("+xhr.status+").");
      if (opts.success) { opts.success(data, status, xhr); }
    },
    error: function(xhr, status, error){
      console.error("Request "+method+" "+url+" failed with error: "+error+", status: "+xhr.status+".");
      if (opts.error) { opts.error(xhr, status, error); }
    }
  });
};
