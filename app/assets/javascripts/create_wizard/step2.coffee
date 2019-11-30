# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).on 'load', ->
  max = Number(document.getElementById('hidden').innerText)
  count = 0
  $("input#create_name").each () ->
    $(this).attr('name','create['+count+'][image]')
    if count == max
      count = 0
    else
      count++
  $("input#create_port").each () ->
    $(this).attr('name','create['+count+'][port]')
    if count == max
      count = 0
    else
      count++
