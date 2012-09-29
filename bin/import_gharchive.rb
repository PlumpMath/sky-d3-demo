#!/usr/bin/env ruby

require "rubygems"
require 'bundler'
Bundler.require

################################################################################
#
# Globals
#
################################################################################

# Stores a hash of usernames to generated ids. GitHub Archive doesn't provide
# an actor_id so we're hacking it.
actors = {}

# An autoincrementing counter for actor id.
current_actor_id = 0;


################################################################################
#
# Functions
#
################################################################################

# Prints the proper usage of this command to the console.
def usage(msg=nil)
  puts msg unless msg.nil?
  puts "./import_gharchive.rb PATH"
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
    if actors.has_key?(json['actor'])
      current_actor_id += 1
      actors[json['actor']] = current_actor_id
    end
    actor_id = actors[json['actor']]
  end
  
  #payload = json.has_key?('payload') ? json['payload'] : nil
  #case json['type']
  #when 'CommitCommentEvent' then puts json; return nil #return [payload['user']['id'], {}]
  #end
  
  return [actor_id, {}]
end
  

################################################################################
#
# Main
#
################################################################################

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

# Validate path to the archive directory.
path = ARGV.first
usage("Path required:") if path.nil? || path == ""
usage("Path does not exist:") unless File.exists?(path)

# Retrieve files.
files = File.directory?(path) ? Dir.glob("#{path}/*.json") : [path]
usage("Directory contains no archive files (*.json)") if files.length == 0
files.map! {|file| File.expand_path(file)}

# Maintain cache of properties & actions.
actions = {}
properties = {}

# Open each file and import it.
files.each_with_index do |file, index|
  percent_complete = index == files.length-1 ? 1 : (index.to_f/files.length.to_f)
  bar_unit_count = (percent_complete * 30).ceil
  bar = '#' * bar_unit_count
  print "#{'%-40s' % File.basename(file)}|#{'%-30s' % bar}|\r"

  # Read each line of the file as an event.
  File.open(file, 'r').each_line do |line|
    json = JSON.parse(line)
    actor_id, data = extract(json)
    puts "#{data['type']}: #{actor_id}" unless actor_id.nil?
  end
end

puts
puts