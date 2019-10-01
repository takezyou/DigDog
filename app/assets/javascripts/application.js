// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require_tree .
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require turbolinks

// https://qiita.com/u-dai/items/d43e932cd6d96c09b69aを参考に作成

// CSRF対策
$.ajaxSetup({
  headers: {
    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
  }
});

$(function() {
  $('button#delete').on('click', function() {
    var id = $('button#delete').attr('data')
    var check = confirm('Deployment "'+id+'" を削除しますか？');

    if(check == true) {
      $.ajax({
        url: '/delete',
        type: 'POST',
        data: {'deployment': id, '_method': 'DELETE'}
      })

     .done(function() {
        clickEle.parents('tr').remove();
      })

     .fail(function() {
        alert('エラーが発生しました。\n時間をおいてもう一度お試しください。');
      });

    } else {
      (function(e) {
        e.preventDefault()
      });
    };
  });
});
