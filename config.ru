require 'rubygems'
require 'bundler'
Bundler.require
require './app'

# Setup client.
SkyDB.database = 'gharchive-apr-2012'
#SkyDB.database = 'gharchive'
SkyDB.table = 'users'

# Run demo server.
run SkyD3Demo
