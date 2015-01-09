#!/usr/bin/env ruby

# Copyright (c) 2015, Göran Gustafsson. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

###############################################################################
# Version: 1.0                                                                #
#     Web: https://github.com/ggustafsson/Event-Log-System                    #
#     Git: https://github.com/ggustafsson/Event-Log-System.git                #
#   Email: gustafsson.g@gmail.com                                             #
###############################################################################

bar_graphs_latest = 1 # Show graphs for latest 24 hours and 31 days? On/off.
bar_graphs_color1 = "#88c157" # Color for latest 24 hours and 31 days.
bar_graphs_color2 = "#4086cc" # Color for everything else.

###############################################################################
# Do not change anything below this line unless you know what you are doing.  #
###############################################################################

unless ARGV.length == 2
  puts "Usage: #{File.basename($0)} [LOGFILE]... [OUTPUT]..."
  exit
end

require "csv"
require "date"
require "time"

input = ARGV[0]
input_filename = File.basename(input)
output = ARGV[1]

if !File.exist?(input)
  abort "File '#{input}' does not exist! Exiting..."
elsif CSV.read(input).empty?
  abort "No entries found! Exiting..."
end

external_dir = File.dirname($0)
external_css = "#{external_dir}/EventParser-files/External.css"
external_js1 = "#{external_dir}/EventParser-files/Chart.min.js"
external_js2 = "#{external_dir}/EventParser-files/External.js"

if !File.exist?(external_css)
  abort "File '#{external_css}' does not exist! Exiting..."
elsif !File.exist?(external_js1)
  abort "File '#{external_js1}' does not exist! Exiting..."
elsif !File.exist?(external_js2)
  abort "File '#{external_js2}' does not exist! Exiting..."
end

events = 0 # Contains total amount of logged events.
events_dev = Hash.new(0) # Contains events per device.
events_date_min = "" # Contains oldest entry date.
events_date_max = "" # Contains newest entry date.

lhours = Hash.new(0) # Contains events from latest 24 hours.
lmonthdays = Hash.new(0) # Contains events from latest 31 days.
hours = Hash.new(0) # Contains all events per hour.
weekdays = Hash.new(0) # Contains all events per weekday.
monthdays = Hash.new(0) # Contains all events per day of month.
months = Hash.new(0) # Contains all events per month.

# Create all hash entries before hand so we get the right order. All keys must
# be saved and always used as integers (NOT strings) to avoid data loss!
(0..23).each{ |lhour| lhours[0 - lhour] = 0 } # Negative numbers.
(0..30).each{ |lmonthday| lmonthdays[0 - lmonthday] = 0 } # Same here.
(0..23).each{ |hour| hours[hour] = 0 }
(1..7 ).each{ |weekday| weekdays[weekday] = 0 }
(1..31).each{ |monthday| monthdays[monthday] = 0 }
(1..12).each{ |month| months[month] = 0 }

$bar_graphs = 0 # Counter for automatic numbering of bar graphs.
# Need both Date and Time data types. Time for dealing with latest 24 hours and
# Date for dealing with the latest 31 days.
parse_date = Date.today
parse_time = Time.now

puts "Parsing '#{input}' and writing to '#{output}'..."

CSV.foreach(input) do |row|
  unless row.size == 4
    puts "The row on line #{$.} is not 4 columns. Skipping!"
    next
  end

  begin
    event_date = Date.parse(row[0])
    event_time = Time.parse(row[1])
  rescue
    puts "Invalid date or time on line #{$.}. Skipping!"
    next
  end

  # Date field and time field put together. This is needed to correctly
  # calculate time between event and now later on.
  event_date_time = Time.parse("#{row[0]} #{row[1]}")

  events += 1
  events_dev[row[2].to_i] += 1

  # Save event date the first time and after that always compare values.
  if events_date_min == ""
    events_date_min = event_date
  elsif event_date < events_date_min
    events_date_min = event_date
  end
  if events_date_max == ""
    events_date_max = event_date
  elsif event_date > events_date_max
    events_date_max = event_date
  end

  # Check if event date is within the latest 31 days.
  if event_date > parse_date - 31
    days_since = (event_date - parse_date).to_i
    hours_since = ((event_date_time - parse_time) / 60 / 60).to_i
    lmonthdays[days_since] += 1

    # Check if event time is within the latest 24 hours.
    if hours_since >= -23
      lhours[hours_since] += 1
    end
  end

  # These values are used as hash keys afterwards. Must be integers!
  hour = event_time.strftime("%k").to_i # 0-23
  weekday = event_date.strftime("%u").to_i # 1-7
  monthday = event_date.strftime("%-d").to_i # 1-31
  month = event_date.strftime("%-m").to_i # 1-12

  # Add 1 to the value of each hash key above.
  hours[hour] += 1
  weekdays[weekday] += 1
  monthdays[monthday] += 1
  months[month] += 1
end

# Sort events per device after which device has the biggest values.
events_dev = events_dev.sort_by{ |key, value| value }.reverse
devices = events_dev.count # Contains the number of devices used.

# Create all data and label strings that are used with Chart.js later on.
# Basically all values in the hashes separated by a comma character. Custom
# labels can also be used but the values must be inside of quotes so that
# JavaScript doesn't see them as variables.
lhours_lbl = lhours.map{ |key, value| key }.join(",")
lhours_val = lhours.map{ |key, value| value }.join(",")
# Converting key value to the specific date instead of using -X.
lmonthdays_lbl = lmonthdays.map{ |key, value| (parse_date + key).strftime("%-d") }.join(",")
lmonthdays_val = lmonthdays.map{ |key, value| value }.join(",")
# Keep the value but add leading zero to make it look like a time format.
hours_lbl = hours.map{ |key, value| "'%02d'" % key }.join(",")
hours_val = hours.map{ |key, value| value }.join(",")
weekdays_lbl = "'Mon','Tue','Wed','Thu','Fri','Sat','Sun'"
weekdays_val = weekdays.map{ |key, value| value }.join(",")
monthdays_lbl = monthdays.map{ |key, value| key }.join(",")
monthdays_val = monthdays.map{ |key, value| value }.join(",")
months_lbl = "'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'"
months_val = months.map{ |key, value| value }.join(",")

# Function used to easily create each bar graph.
def bar_graph(title, labels, values, color)
  $bar_graphs += 1

  html = "<h2>#{$bar_graphs}. #{title}</h2>
<canvas id='bar_graph#{$bar_graphs}' width='640' height='280'></canvas>
<script>
  new Chart(
    document.getElementById('bar_graph#{$bar_graphs}').getContext('2d')
  ).Bar({
    labels: [#{labels}],
    datasets: [{
      data: [#{values}],
      fillColor: '#{color}',
      strokeColor : '#{color}'
    }]
  });
</script>"

  return html
end

File.open(output, "w") do |page|
  page.puts "<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='UTF-8'>
<title>EventParser - #{input_filename}</title>
<style>
#{File.read(external_css)}
</style>
<script>
#{File.read(external_js1)}
#{File.read(external_js2)}
</script>
</head>
<body>
<div id='main'>
<h1>Summarisation of log file '#{input_filename}'</h1>
<p>Log file parsed at <b>#{parse_time.strftime("%Y-%m-%d %H:%M:%S")}</b></p>
<p><b>#{events}</b> logged events from <b>#{devices}</b> device(s)</p>"
  # Display specific stats only if several devices have been used.
  if devices > 1
    page.puts "<ul>"
    events_dev.each do |key, value|
      page.puts "<li><b>#{value}</b> events from device <b>#{key}</b></li>"
    end
    page.puts "</ul>"
  end
  page.puts "<p>Date ranges from <b>#{events_date_min}</b> to <b>#{events_date_max}</b></p>"
  # Display bar graphs for latest 24 hours and 31 days if the settings is on.
  if bar_graphs_latest == 1
    page.puts bar_graph("Latest 24 hours", lhours_lbl, lhours_val, bar_graphs_color1)
    page.puts bar_graph("Latest 31 days", lmonthdays_lbl, lmonthdays_val, bar_graphs_color1)
  end
  page.puts bar_graph("Events per hour", hours_lbl, hours_val, bar_graphs_color2)
  page.puts bar_graph("Events per weekday", weekdays_lbl, weekdays_val, bar_graphs_color2)
  page.puts bar_graph("Events per day of month", monthdays_lbl, monthdays_val, bar_graphs_color2)
  page.puts bar_graph("Events per month", months_lbl, months_val, bar_graphs_color2)
  page.puts "</div>
</body>
</html>"
end
