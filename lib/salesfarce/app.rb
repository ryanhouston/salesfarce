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
        @notice = "Your session expired and you were logged out!"
      else
        @notice = "#{exception.error_code}: #{exception.message}"
      end
      redirect to("/")
    end

    get '/' do
      puts session.inspect

      haml :home
    end

    get '/users' do
      @users = Databasedotcom::Chatter::User.all(session[:client])

      haml :sf_users
    end

    get '/auth/salesforce/callback' do
      session[:client] = Databasedotcom::Client.new("config/salesforce.yml")
      session[:client].authenticate request.env['omniauth.auth']
      redirect to("/")
    end

    def self.start
      run!
    end
  end
end

