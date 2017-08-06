##################
#
# ics_calender job will load one or more ics calendars and process them to be presented using
# one or more ics_calendar_items widgets
#
# Adopted from Confluence Calendar https://gist.github.com/rahulsom/350f00cd49c782157ee4
#
##################

require 'net/http'
require 'icalendar'
require 'icalendar/recurrence'
require 'time'
require 'tzinfo'
require 'pp'

# For an Owncloud instance, the calendar will live at 
# https://OWNCLOUD_SRV/owncloud/remote.php/caldav/calendars/USERNAME/CALENDARNAME?export

CONFLUENCE_URI = URI.parse('https://asimov.creativethings.org/owncloud')
DATE_FORMAT =  '%Y-%m-%dT%H:%M:%S%z'
BASIC_AUTH_USERNAME = "niels"
BASIC_AUTH_PASSWRD = "DrolneyRyp"

# Fetch below calendars
CALENDARS = {
    :afval   => 'afvalkalender',
    :huis    => 'huis',
    :joost   => 'joost',
}

CONFLUENCE_HTTP = Net::HTTP.start(CONFLUENCE_URI.host, CONFLUENCE_URI.port, :use_ssl => CONFLUENCE_URI.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE)

class Event2
  attr_reader :summary
  attr_reader :dtend
  attr_reader :dtstart
  attr_reader :attendee

  def initialize(summary, dtstart, dtend, attendee)
    @summary  = summary
    @dtend    = dtend
    @dtstart  = dtstart
    @attendee = attendee
  end
end

def get_calendar(http, user, cal_id)
  cal_root = '/remote.php/caldav/calendars/'
  request  = Net::HTTP::Get.new("#{CONFLUENCE_URI.path}/#{cal_root}/#{user}/#{cal_id}?export")
  request.basic_auth(BASIC_AUTH_USERNAME, BASIC_AUTH_PASSWRD)
  response = http.request(request)
  response.body
end

def event_hash(event, tz)

  # format w/ timezone info
  def get_time(t, tz)
    if t.to_s.include?('UTC')
      format_datetime(t.utc, DATE_FORMAT)
    else
      t1 = use_time_zone(t, tz)
      format_datetime(t1.utc, DATE_FORMAT)
    end
  end

  interval = event.dtend - event.dtstart
  delta = interval < (60*60*24) ? 0 : Rational(1, 60*60*24)
  attendees = event.attendee.collect { |att| att.ical_params['cn'] }.join(', ')
  
  # prep data for display
  {
      :summary   => event.summary,
      :start     => get_time(event.dtstart + delta, tz),
      :end       => get_time(event.dtend - delta, tz),
      :attendees => attendees,
      :show      => event.summary.include?(attendees) ? 'hidden' : ''
  }
end

def with_time_zone(tz_name)
  prev_tz = ENV['TZ']
  puts prev_tz
  
  ENV['TZ'] = tz_name
  yield
ensure
  ENV['TZ'] = prev_tz
end

def format_datetime(t, format)
  return t.strftime(format)
end

def use_time_zone(t, tz)
  with_time_zone(tz) {Time.new(t.year, t.month, t.mday, t.hour, t.min, t.sec)}
end

def update_calendar(http)
  CALENDARS.each do |key, identifier|

    #For each calendar get the ics file and parse it
    ics       = get_calendar(http, "niels", identifier)
    
    # Does ICS allow more then one calendar in a file?
    calendars = Icalendar::Calendar.parse(ics)

    # for each calendar
    calendars.each do |calendar|

    # this does not work for owncloud calendar data
    tz = calendar.x_wr_timezone[0].to_s

    cal_data = calendar.events.
          collect { |event|          
            event.rrule ?
             # if we are dealing with a recurring event , calulate the next time it is happening.

             #for the next 90 days create the recurrign events as normal events
             event.occurrences_between(Date.today - 1, Date.today + 90).
               collect { |occurrence|
			     # put the newly created events in the cal-data object
                    Event2.new(event.summary, occurrence.start_time, occurrence.end_time, event.attendee)
                 } :
                
               # Else just use the regular dtstat, dtend, summary and attendees
               [Event2.new(event.summary, event.dtstart, event.dtend, event.attendee)]
          }.
          flatten.
          
          # now select events and use event_hash function too format them for presentation
          select { |event| event.is_a?(Date) ? event.dtend > Date.today - 1 : event.dtend > Time.now }.
          collect { |event| event_hash(event, tz) }.
          sort_by { |event| event[:start] }.
          take(7)

      puts cal_data

      send_event("#{key}-Calendar", {:data => cal_data})

    end
  end
end

SCHEDULER.every '15m', :first_in => 0 do |id|
  update_calendar(CONFLUENCE_HTTP)
end

