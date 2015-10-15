begin
  require 'sinatra'
  require 'omniauth'
  require 'omniauth-slack'
  require 'slack'
end

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :slack, ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"], scope: "read", team: "T08NRT4DU"
end

get '/' do
  <<-HTML
  <a href='/auth/slack'>Sign in with Slack</a>
  HTML
end

get '/auth/slack/callback' do
  auth = request.env['omniauth.auth']
  client = Slack::RPC::Client.new(auth.credentials.token)
  client.channels.history(:channel => "C097E9TFD") do |response|
      #check the response.status and do something with the response.body
  end
end