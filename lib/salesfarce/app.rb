require 'yaml'
require 'sinatra/base'
require 'rack-flash'
require 'haml'
require 'omniauth'
require 'oa-oauth'
require 'databasedotcom'
require 'salesforce_strategy'
require 'data_mapper'
require 'salesfarce/user'


module Salesfarce
  class App < Sinatra::Base
    use Rack::Flash, :sweep => true

    configure do
      set :port, 3000
      set :root, File.expand_path('../../../', __FILE__)
      enable :method_override
      enable :sessions

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure

      @sf_config ||= YAML.load_file('config/salesforce.yml')
    end

    configure :production do
      db_file = File.join("sqlite3://", settings.root, "data/production.db")
      DataMapper.setup(:default, db_file)
      DataMapper.auto_upgrade!
    end

    configure :development, :test do
      db_file = File.join("sqlite3://", settings.root, "data/development.db")
      DataMapper.setup(:default, db_file)
      DataMapper::Logger.new($stdout, :debug)
      DataMapper.auto_migrate!
    end


    use OmniAuth::Strategies::Salesforce, @sf_config['client_id'], @sf_config['client_secret']

    error Databasedotcom::SalesForceError do
      exception = env['sinatra.error']
      if exception.error_code == "INVALID_SESSION_ID"
        session[:client] = nil
        flash[:notice] = "Your session expired and you were logged out!"
      else
        flash[:notice] = "#{exception.error_code}: #{exception.message}"
      end

      redirect to('/')
    end

    error do
      @exception = exception

      haml :error
    end

    not_found do
      haml :not_found
    end

    before do
      @authenticated = true

      unless (session[:client])
        flash[:notice] = 'You are not authenticated with Salesforce'
        @authenticated = false
        redirect to('/') if protected_routes.include? request.path_info
      end
    end

    def protected_routes
      ['/sf_users']
    end

    get '/auth/salesforce/callback' do
      session[:client] = Databasedotcom::Client.new("config/salesforce.yml")
      session[:client].authenticate request.env['omniauth.auth']
      session[:client].sobject_module = Salesfarce::SObject
      redirect to("/")
    end

    get '/logout' do
      session[:client] = nil
      redirect to('/')
    end

    get '/' do
      haml :home
    end

    get '/sf_users' do
      session[:client].materialize('User')
      @users = SObject::User.all

      haml :sf_users
    end

    get '/users' do
      @users = Salesfarce::User.all

      haml :users
    end

    get '/user/new' do
      @user = Salesfarce::User.new

      haml :user_new
    end

    post '/user/create' do
      @user_params = params[:user]
      @user = Salesfarce::User.create(
        :created_at => Time.now,
        :username => @user_params[:username],
        :first_name => @user_params[:first_name],
        :last_name => @user_params[:last_name],
        :company => @user_params[:company],
        :title   => @user_params[:title],
        :phone   => @user_params[:phone],
        :mobile_phone => @user_params[:mobile_phone],
        :bio => @user_params[:bio]
      )

      flash[:notice] = "New User Created!"
      redirect to('/user/' + @user.id.to_s)
    end

    get '/user/:id' do
      @user = Salesfarce::User.get(params[:id])

      @user ? haml(:user) : 404
    end

    get '/user/:id/edit' do
      @user = Salesfarce::User.get(params[:id])

      haml :user_edit
    end

    put '/user/:id/update' do
      @user_params = params[:user]
      @user = Salesfarce::User.get(params[:id])

      # TODO actually update with the given params

      redirect to("/user/#{@user.id}")
    end

    def self.start
      run!
    end
  end
end

