# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).on 'load', ->
  count = 0
  document.getElementById('create_image').setAttribute('name','create['+count+'][image]')
  $('button#plus').on 'click', ->
    original = document.getElementById('form-content['+count+']')
    count++
    clone = original.cloneNode(true)
    clone.setAttribute("id",'form-content['+count+']')
    clone.childNodes[1].childNodes[5].setAttribute('name','create['+count+'][image]')
    document.getElementById('form-contents').append(clone)
    document.getElementById('create_count').setAttribute('value',count)

  $('button#minus').on 'click', ->
    console.log "hoge"
    return
