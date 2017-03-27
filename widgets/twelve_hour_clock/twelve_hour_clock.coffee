class Dashing.TwelveHourClock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 1000)

  startTime: =>
    weekdays_nl = ["Zondag", "Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag"]
    today    = new Date()
    #hours    = @getHours(today.getHours())
    hours    = today.getHours()
    minutes  = @formatTime(today.getMinutes())
    meridiem = @getMeridiem(today.getHours())
    #@set('weekday', weekdays_nl[3].toString())
    @set('weekday', "Dus")
    @set('time', hours + ":" + minutes)
    @set('date', today.toLocaleDateString("nl-nl"))

  getHours: (i) ->
    ((i + 11) %% 12) + 1

  getMeridiem: (i) ->
    if i < 12 then "AM" else "PM"

  formatTime: (i) ->
    if i < 10 then "0" + i else i
