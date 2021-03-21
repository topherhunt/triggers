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
}
