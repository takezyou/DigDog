# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).on 'load', ->
  if document.getElementById("success_alert") != null
    $('select#domain_svc').find('option:selected').prop('selected', false);
    $('input#domain_name').val('');
    $('input#domain_port').val('');
  return

$(window).on 'load', ->
  # CSRF対策
  $.ajaxSetup
    headers: {
      'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }
  value = $('select#domain_svc').val()
  user = $('div.current_username').text().replace(/(\s+)|(\n)/g, "")
  $.ajax
    url: '/info_domain'
    type: 'POST'
    data: {'deployment': value, 'current_user': user}
  .done (data,status,XHR) ->
    if data["status"] == "Success"
      $("input#domain_port").val(data["port"])
    else
      alert 'エラーが発生しました。\nページをリロードしてください。'
  .fail ->
    alert 'エラーが発生しました。\nページをリロードしてください。'


$(document).on 'change', 'select#domain_svc', ->
  e = $(@)
  value = e.val()
  user = $('div.current_username').text().replace(/(\s+)|(\n)/g, "")
  $.ajax
    url: '/info_domain'
    type: 'POST'
    data: {'deployment': value, 'current_user': user}
  .done (data,status,XHR) ->
    if data["status"] == "Success"
      console.log data
      $("input#domain_port").val(data["port"])
    else
      alert 'エラーが発生しました。\nページをリロードしてください。'
  .fail ->
    alert 'エラーが発生しました。\nページをリロードしてください。'
