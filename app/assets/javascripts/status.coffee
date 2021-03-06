# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# https://qiita.com/u-dai/items/d43e932cd6d96c09b69aを参考に作成

$(window).on 'load', ->
  # CSRF対策
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
        if e.parents('tbody').find('tr').length == 1
          $('#deploy').html('<p>対象が存在しません</p>')
        else
          e.parents('tr').remove()
      .fail ->
        alert 'エラーが発生しました。\n時間をおいてもう一度お試しください。'

  $('button#delete_domain').on 'click', ->
    e = $(@)
    id = e.attr('data')
    check = confirm 'Domain "'+id+'" を削除しますか？'

    if check == true
      $.ajax
        url: '/delete_domain'
        type: 'POST'
        data: {'domain': id, '_method': 'DELETE'}
      .done ->
        if e.parents('tbody').find('tr').length == 1
          $('#domain').html('<p>対象が存在しません</p>')
        else
          e.parents('tr').remove()
      .fail ->
        alert 'エラーが発生しました。\n時間をおいてもう一度お試しください。'

  $('button#expand').on 'click', ->
    e = $(@)
    id = e.attr('data')
    check = confirm 'Deployment "'+id+'" に対して延長申請を行いますか？\n(管理者によるチェックが行われます)'

    if check == true
      $.ajax
        url: '/expand'
        type: 'POST'
        data: {'deployment': id}
      .done ->
        html = '<div align="center"><span class="badge badge-secondary">承認待ち</span></div>'
        $('#'+id+'_status-badge').html(html)
        e.parents('tr').find('button#expand').remove()
      .fail ->
        alert 'エラーが発生しました。\n時間をおいてもう一度お試しください。'
  return
