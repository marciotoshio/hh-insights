require 'sinatra'
require 'sinatra/reloader' if development?
require 'byebug' if development?
require 'omniauth'
require 'omniauth-slack'
require 'sequel'
require 'chartkick'
require './requests'

configure do
  set :slack_team_id, 'T08NRT4DU'
  set :slack_channel_id, 'C097E9TFD'
end

configure :development do
  set :conn_string, 'sqlite://hh-insights.db'
end

configure :test do
  set :conn_string, 'sqlite3::memory:'
end

#OAUTH
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :slack, ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"], scope: "read", team: settings.slack_team_id
end

DB = Sequel.connect(settings.conn_string)
DB.create_table? :hh_requests do
  primary_key :id
  String :department
  String :description
  Real :timespan
end
dataset = DB.from(:hh_requests) 

def get_requests(ds)
  Requests.new(ds)
end

#CONTROLLERS
get '/' do
  requests = get_requests(dataset)
  @all_requests = requests.all
  @department_group_count = requests.department_group_count
  @departments_by_hour = requests.departments_by_hour
  erb :index
end

get '/save_newest_messages' do
  requests = get_requests(dataset)
  requests.save_newest_messages(session['token'], settings.slack_channel_id)
  "done"
end

get '/save_oldest_messages' do
  requests = get_requests(dataset)
  requests.save_oldest_messages(session['token'], settings.slack_channel_id)
  "done"
end

get '/auth/slack/callback' do
  auth = request.env['omniauth.auth']
  session['token'] = auth.credentials.token
  session['nickname'] = auth.info.nickname
  redirect to('/')
end