# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).on 'load', ->
  if document.getElementById("success_alert") != null
    $('select#domain_svc').find('option:selected').prop('selected', false);
    $('input#domain_name').val('');
    $('input#domain_port').val('');
  return
