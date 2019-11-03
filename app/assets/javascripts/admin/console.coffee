# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  $('#v-pills-deploy').load '/admin/deploy'
  $('#v-pills-admin').load '/admin/admin', ->
    $('#editModal').on 'show.bs.modal', (e) ->
      $('input#deploy_is_recognize').val($('input#hidden_is_recognize').val())
      $('input#deploy_name').val($('input#hidden_name').val())
      $('input#deploy_space').val($('input#hidden_space').val())
      $('.modal-title').text('Deployment : '+$('input#hidden_name').val())
    return
