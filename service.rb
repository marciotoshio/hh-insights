begin
  require 'sinatra'
  require 'sinatra/reloader' if development?
  require 'byebug' if development?
  require 'omniauth'
  require 'omniauth-slack'
  require 'slack'
  require 'sequel'
  require 'chartkick'
end

#CONFIG
set :requests_channel_id, 'C097E9TFD'

#OAUTH
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :slack, ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"], scope: "read", team: "T08NRT4DU"
end

#DATA
DB = Sequel.connect('sqlite://hh-insights.db')
DB.create_table? :hh_requests do
  primary_key :id
  String :department
  String :description
  Real :timespan
end

#MODELS
hh_requests = DB.from(:hh_requests)

#SERVICES
def get_slack_client
  Slack::RPC::Client.new(session['token'])
end

def save_newest_messages(hh_requests)
  get_slack_client.channels.history(channel: settings.requests_channel_id, oldest: hh_requests.max(:timespan)) do |response|
    save_messages(hh_requests, response.body['messages'])
    #get_newest_messages(hh_requests.max(:timespan)) if response.body['has_more'] == true
  end
end

def save_oldest_messages(hh_requests)
  get_slack_client.channels.history(channel: settings.requests_channel_id, latest: hh_requests.min(:timespan)) do |response|
    save_messages(hh_requests, response.body['messages'])
    #get_oldest_messages(hh_requests.min(:timespan)) if response.body['has_more'] == true
  end
end

def save_messages(hh_requests, messages)
  messages.each do |m|
    hh_requests.insert(department: m['text'].match('\[\*_(.+)_\*\]')[1], description: m['text'], timespan: m['ts']) if m['subtype'] == 'bot_message'
  end
end

def department_group_count(hh_requests)
  hh_requests.group_and_count(:department).all.map{|d| [d[:department], d[:count]]}
end

def group_department_by_hour(hh_requests, department)
  requests_from_department = hh_requests.where(department: department).all
  result = {}
  (1..24).each do |hour|
    result.merge! Hash[Time.parse("2015-01-01 #{hour}:00").to_s, requests_from_department.count { |r| Time.at(r[:timespan]).hour >= hour && Time.at(r[:timespan]).hour < hour + 1 }]
  end
  result
end

def departments_by_hour(hh_requests)
  all_departments = hh_requests.select_group(:department).all
  all_departments.map do |d|
    Hash['department', d[:department], 'value', group_department_by_hour(hh_requests, d[:department])]
  end
end

#CONTROLLERS
get '/' do
  @all_requests = hh_requests.all
  @department_group_count = department_group_count(hh_requests)
  @departments_by_hour = departments_by_hour(hh_requests)
  erb :index
end

get '/save_newest_messages' do
  save_newest_messages(hh_requests)
  "done"
end

get '/save_oldest_messages' do
  save_oldest_messages(hh_requests)
  "done"
end

get '/auth/slack/callback' do
  auth = request.env['omniauth.auth']
  session['token'] = auth.credentials.token
  session['nickname'] = auth.info.nickname
  redirect to('/')
end