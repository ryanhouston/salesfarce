require 'oauth2'
require 'sinatra'
require 'yaml'

set :port, 3000
set :sessions, true

def config
  if (File.exists?('config.yml'))
    @config ||= YAML::load_file('config.yml')
  else
    raise "No config file"
  end
end

def oauth_client
  OAuth2::Client.new(
    config['salesforce']['client_id'],
    config['salesforce']['client_secret'],
    :site          => "https://login.salesforce.com",
    :authorize_url => '/services/oauth2/authorize',
    :token_url     => '/services/oauth2/token',
    :raise_errors => false
  )
end

before do
  pass if request.path_info == '/oauth/_callback'
end

get '/' do
end

get '/oauth/_callback' do
  begin
    access_token = oauth_client.auth_code.get_token(
      params[:code],
      :redirect_uri => "http://localhost:3000/oauth/_callback"
    )
puts access_token.inspect
    session['access_token'] = access_token.token
    session['refresh_token'] = access_token.refresh_token
    session['instance_url'] = access_token.params['instance_url']

    puts session.inspect
    #redirect '/'
  rescue => exception
    output = '<html><body><tt>'
    output += "Exception: #{exception.message}<br/>"+exception.backtrace.join('<br/>')
  end
end

get '/authorize' do
  redirect oauth_client.auth_code.authorize_url(:redirect_uri => 'http://localhost:3000/oauth/_callback')
end

