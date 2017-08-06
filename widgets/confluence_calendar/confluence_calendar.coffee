class Dashing.ConfluenceCalendar extends Dashing.Widget

  computeRange: (start, end) ->
    moment.locale("nl")  
  
    range = moment(start).twix(end)
    allDayRange = moment(start).twix(end, {allDay: true})
    if (range.asDuration().asHours() > 8 || start == end)
      retval = allDayRange.format({showDayOfWeek: true})
    else
      retval = range.format({showDayOfWeek: true})
    retval

  ready: ->
    for td in jQuery('td.ccrange')
      $td = jQuery(td)
      range = @computeRange($td.attr('start'), $td.attr('end'))
      $td.html(range)

  onData: (data) ->
    for row in data.data
      row.range = @computeRange(row.start, row.end)
