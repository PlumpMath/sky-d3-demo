#!/usr/bin/env ruby

require "rubygems"
require 'bundler'
Bundler.require
require 'open-uri'
require 'date'
require 'zlib'


################################################################################
#
# Globals
#
################################################################################

# Stores a hash of usernames to generated ids. GitHub Archive doesn't provide
# an actor_id so we're hacking it.
$actors = {}

# An autoincrementing counter for actor id.
$current_actor_id = 0;

# Maintain cache of properties & actions.
current_action_id = 0
actions = {}
properties = {}
event_count = 0



################################################################################
#
# Functions
#
################################################################################

# Prints the proper usage of this command to the console.
def usage(msg=nil)
  puts msg unless msg.nil?
  puts "./import_gharchive.rb START_DATE END_DATE"
  exit(1)
end

# Extracts the actor id and relavent data to import for a given event.
#
# @param [Hash] json  the json data for the event.
# @return [Array]  an array containing actor id and the data hash.
def extract(json)
  # Determine actor id.
  actor_id = nil
  if !json['actor'].nil?
    if !$actors.has_key?(json['actor'])
      $current_actor_id += 1
      $actors[json['actor']] = $current_actor_id
    end
    actor_id = $actors[json['actor']]
  end
  
  #payload = json.has_key?('payload') ? json['payload'] : nil
  #case json['type']
  #when 'CommitCommentEvent' then puts json; return nil #return [payload['user']['id'], {}]
  #end
  
  return [json['actor'], actor_id, {}]
end
  

################################################################################
#
# Main
#
################################################################################

# Parse start and end dates.
start_date, end_date = ARGV
start_date = Chronic.parse(start_date)
if end_date.nil?
  end_date = start_date
else
  end_date = Chronic.parse(end_date)
end
usage if start_date.nil?
start_date = start_date.to_date
end_date = end_date.to_date

# Confirm that user wants to delete github archive database.
database_path = "/usr/local/sky/data/gharchive"
if File.exists?(database_path)
  print "Are you sure you want to overwrite the Sky gharchive database? [yN] "
  c = STDIN.getc.chr.chomp
  exit(0) if c == '' || c == 'N'
  FileUtils.rm_rf(database_path)
end

# Create users table.
FileUtils.mkdir_p("#{database_path}/users")

# Setup client.
SkyDB.database = 'gharchive'
SkyDB.table = 'users'
#SkyDB.debug = true

# Loop over days.
(start_date..end_date).each do |date|
  # Loop over hours in the day.
  24.times do |hour|
    puts "PROCESSING: #{date.strftime('%Y-%m-%d')} #{hour}h"

    # Open gzip file and read contents
    gz = open("http://data.githubarchive.org/#{date.strftime('%Y-%m-%d')}-#{hour}.json.gz")
    content = Zlib::GzipReader.new(gz).read

    # Parse each line using JSON
    Yajl::Parser.parse(content) do |json|
      actor, actor_id, data = extract(json)

      puts "#{'%07d' % event_count} [#{json['type']}]: #{actor}"
    
      # Add action if it doesn't exist.
      if !actions.has_key?(json['type'])
        SkyDB.aadd(SkyDB::Action.new(:name => json['type']))
        current_action_id += 1
        actions[json['type']] = current_action_id
      end
    
      # Add event if there is an actor.
      if !actor_id.nil?
        action_id = actions[json['type']]
        event = SkyDB::Event.new(
          :object_id => actor_id,
          :timestamp => DateTime.parse(json['created_at']),
          :action_id => action_id
          )
        SkyDB.eadd(event)

        event_count += 1
      end
    end
  end
end
