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
    @actions = SkyDB.aall()['actions']
    erb :index
  end

  # Retrieve an array of next steps given an array of action ids.
  get '/next_actions' do
    # Get list of action ids from client.
    action_ids = params[:actionIds].split(/,/).map {|x| x.to_i}
  
    # Generate query for Sky.
    query = <<-BLOCK
      // The result type to return to the client.
      [Hashable("actionId")]
      [Serializable]
      class Result {
        public Int actionId;
        public Int count;
      }
    
      // Main program.
      Int targetActionId = #{action_ids[0]};
      Int previousActionId;
      Cursor cursor = path.events();
      for each (Event event in cursor) {
        // If the last action was our target then add a count
        // for the current action.
        if(previousActionId == targetActionId) {
          Result item = data.get(event.actionId);
          item.count = item.count + 1;
        }
      
        // Keep track of the previous action.
        previousActionId = event.actionId;
      }

      return;
    BLOCK

    # Setup the client
    SkyDB.database = 'gharchive'
    SkyDB.table = 'users'

    # Run query once against each path in the database.
    result = SkyDB.peach(query)
  
    # Convert the result to JSON and return it.
    content_type :json
    return result.to_json
  end
end