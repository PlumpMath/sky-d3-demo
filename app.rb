require 'rubygems'
require 'sinatra'

# Setup public folder.
set :public_folder, File.dirname(__FILE__) + '/public'

# Redirect root to index.html
get '/' do
  redirect '/index.html'
end
