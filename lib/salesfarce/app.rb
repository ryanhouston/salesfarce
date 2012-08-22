require 'yaml'
require 'sinatra/base'
require 'haml'
require 'omniauth'
require 'oa-oauth'
require 'databasedotcom'
require 'salesforce_strategy'

module Salesfarce
  class App < Sinatra::Base

    set :port, 3000
    set :views, File.expand_path('../../../views', __FILE__)
    enable :sessions

    @sf_config ||= YAML.load_file('config/salesforce.yml')

    use OmniAuth::Strategies::Salesforce, @sf_config['client_id'], @sf_config['client_secret']

    error Databasedotcom::SalesForceError do
      exception = env['sinatra.error']
      if exception.error_code == "INVALID_SESSION_ID"
        session[:client] = nil
        @flash[:notice] = "Your session expired and you were logged out!"
      else
        @flash[:notice] = "#{exception.error_code}: #{exception.message}"
      end
    end

    before do
      @authenticated = true
      @flash = {}

      unless (session[:client])
        @flash[:notice] = 'You are not authenticated'
        @authenticated = false
        redirect to('/') unless (request.path_info == '/' || /\/auth\/salesforce/.match(request.path_info))
      end
    end

    get '/' do
      haml :home
    end

    get '/users' do
      session[:client].materialize('User')
      @users = User.all

      haml :sf_users
    end

    get '/auth/salesforce/callback' do
      session[:client] = Databasedotcom::Client.new("config/salesforce.yml")
      session[:client].authenticate request.env['omniauth.auth']
      redirect to("/")
    end

    get '/logout' do
      session[:client] = nil
      redirect to('/')
    end

    def self.start
      run!
    end
  end
end

