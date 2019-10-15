# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# https://qiita.com/u-dai/items/d43e932cd6d96c09b69aを参考に作成

# CSRF対策
$(document).on 'turbolinks:load', ->
  $.ajaxSetup
    headers: {
      'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }

  $('button#delete').on 'click', ->
    e = $(@)
    id = e.attr('data')
    check = confirm 'Deployment "'+id+'" を削除しますか？'

    if check == true
      $.ajax
        url: '/delete'
        type: 'POST'
        data: {'deployment': id, '_method': 'DELETE'}
      .done ->
        if e.parents('tr').length == 1
          $('#deploy').html('<p>対象が存在しません</p>')
        else
          e.parents('tr').remove();
      .fail ->
        alert 'エラーが発生しました。\n時間をおいてもう一度お試しください。'
    else
        e.preventDefault()
  return
