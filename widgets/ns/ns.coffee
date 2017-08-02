class Dashing.Ns extends Dashing.Widget

  @accessor 'icon', ->
    if @get('status') == 'disruptions' then 'icon-warning-sign' else 'icon-ok'

  onData: (data) ->
    if data.status
      $(@get('node')).addClass("status-#{data.status}")
