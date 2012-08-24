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
        flash_message(:notice) << "Your session expired and you were logged out!"
      else
        flash_message(:notice) << "#{exception.error_code}: #{exception.message}"
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
        @authenticated = false
        if protected_routes.include? request.path_info
          flash_message(:notice) << 'You are not authenticated with Salesforce'
          redirect to('/')
        end
      end
    end

    def protected_routes
      ['/sf_users']
    end

    def flash_message type
      flash[type] ||= []
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
      @nav_active = :home

      haml :home
    end

    get '/sf_users' do
      session[:client].materialize('User')
      @users = SObject::User.all

      @nav_active = :sf_users
      haml :sf_users
    end

    get '/users' do
      @users = Salesfarce::User.all

      @nav_active = :users
      haml :users
    end

    get '/user/new' do
      @user = Salesfarce::User.new

      @nav_active = :create_user
      haml :user_new
    end

    post '/user/create' do
      user_params = process_user_form_params params[:user]
      user_params[:created_at] = Time.now
      @user = Salesfarce::User.create(user_params)

      if @user.saved?
        flash_message(:notice) << "New User Created!"
        redirect to('/user/' + @user.id.to_s)
      end

      flash[:user_form_errors] = @user.errors.collect{|e| e.to_s}

      @nav_active = :create_user
      haml :user_new
    end

    def process_user_form_params user_params
      {
        :username => user_params[:username],
        :first_name => user_params[:first_name],
        :last_name => user_params[:last_name],
        :company => user_params[:company],
        :title   => user_params[:title],
        :phone   => user_params[:phone],
        :mobile_phone => user_params[:mobile_phone],
        :bio => user_params[:bio]
      }
    end

    get '/user/:id' do
      @user = Salesfarce::User.get(params[:id])

      @nav_active = :users
      @user ? haml(:user) : 404
    end

    get '/user/:id/edit' do
      @user = Salesfarce::User.get(params[:id])

      haml :user_edit
    end

    put '/user/:id/update' do
      user_params = process_user_form_params params[:user]
      @user = Salesfarce::User.get(params[:id])

      if @user.update(user_params)
        flash_message(:notice) << "User successfully updated"
        redirect to("/user/#{@user.id}")
      end

      @nav_active = :create_user
      flash[:user_form_errors] = @user.errors.collect{|e| e.to_s}
      haml :user_edit
    end

    def self.start
      run!
    end
  end
end

