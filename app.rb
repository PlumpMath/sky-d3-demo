require "sinatra/reloader"

class SkyD3Demo < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  #############################################################################
  #
  # Initialization
  #
  #############################################################################

  # Setup public folder.
  set :public_folder, File.dirname(__FILE__) + '/public'


  #############################################################################
  #
  # Routes
  #
  #############################################################################

  get '/' do
    @actions = SkyDB.get_actions()['actions']
    @actions.sort_by! {|action| action[:name]}
    erb :index
  end

  # Retrieve an array of next steps given an array of action ids.
  get '/next_actions' do
    # Get list of action ids from client.
    action_ids = params[:actionIds].split(/,/).map {|x| x.to_i}
    
    # Run query once against each path in the database.
    result = SkyDB.next_actions(action_ids)
  
    # Convert the result to JSON and return it.
    content_type :json
    return result.to_json
  end
end