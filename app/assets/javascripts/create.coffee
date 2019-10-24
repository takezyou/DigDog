# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'turbolinks:load', ->
  if document.getElementById("success_alert") != null
    $('select#create_image').find('option:selected').prop('selected', false);
    $('input#create_name').val('');
    $('input#create_port').val('');
  return
