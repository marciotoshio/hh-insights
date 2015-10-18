require 'slack'

class Requests
  
  def initialize(dataset)
    @hh_requests = dataset
  end
  
  def all
    @hh_requests.all
  end
  
  def save_newest_messages(token, channel_id)
    get_slack_client(token).channels.history(channel: channel_id, oldest: @hh_requests.max(:timespan)) do |r|
      save_messages(r.body['messages'])
    end
  end
  
  def save_oldest_messages(token, channel_id)
    get_slack_client(token).channels.history(channel: channel_id, latest: @hh_requests.min(:timespan)) do |r|
      save_messages(r.body['messages'])
    end
  end
  
  def save_messages(messages)
    messages.each do |m|
      @hh_requests.insert(department: m['text'].match('\[\*_(.+)_\*\]')[1], description: m['text'], timespan: m['ts']) if m['subtype'] == 'bot_message'
    end
  end
  
  def department_group_count
    @hh_requests.group_and_count(:department).all.map{|d| [d[:department], d[:count]]}
  end
  
  def group_department_by_hour(department)
    requests_from_department = @hh_requests.where(department: department).all
    result = {}
    (1..24).each do |hour|
      result.merge! Hash[Time.parse("2015-01-01 #{hour}:00").to_s, requests_from_department.count { |r| Time.at(r[:timespan]).hour >= hour && Time.at(r[:timespan]).hour < hour + 1 }]
    end
    result
  end
  
  def departments_by_hour
    all_departments = @hh_requests.select_group(:department).all
    all_departments.map do |d|
      Hash['department', d[:department], 'value', group_department_by_hour(d[:department])]
    end
  end
  
  private 
  
  def get_slack_client(token)
    Slack::RPC::Client.new(token)
  end
end