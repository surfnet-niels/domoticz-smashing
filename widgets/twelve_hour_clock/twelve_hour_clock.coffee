class Dashing.TwelveHourClock extends Dashing.Widget
  ready: ->
    setInterval(@startTime, 1000)

  getHours: (i) ->
    ((i + 11) %% 12) + 1

  getMeridiem: (i) ->
    if i < 12 then "AM" else "PM"

  formatTime: (i) ->
    if i < 10 then "0" + i else i

  startTime: =>
    weekdays_nl = ["Zondag", "Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag"]   
    months_nl = ["Januari", "Februari", "Maart", "April", "Mei", "Juni", "Juli", "Augustus", "September", "Oktober", "November", "December"]
    today    = new Date()

    #console.log("Weekday : " + weekdays_nl[today.getDay()])
    #console.log(today.getDate() + " - " + months_nl[today.getMonth()] + " - " + today.getFullYear())

    hours    = today.getHours()
    minutes  = @formatTime(today.getMinutes())
    meridiem = @getMeridiem(today.getHours())
    
    @set('weekday', weekdays_nl[today.getDay()])
    @set('time', hours + ":" + minutes)
    @set('date', today.getDate() + " " + months_nl[today.getMonth()] + " " + today.getFullYear())
    #@set('sunrise', "\u21D1 ")
    #@set('sunset', "\u21D3 ")


