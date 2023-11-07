#!/usr/bin/env ruby
require 'faraday'
require 'pry'
require 'json'
require 'dotenv/load'

SERVICE_NOW_BASE_URL = ENV["SERVICE_NOW_BASE_URL"]
USERNAME = ENV["SERVICE_NOW_USERNAME"]
PASSWORD = ENV["SERVICE_NOW_PASSWORD"]
CLIENT_ID = ENV["SERVICE_NOW_CLIENT_ID"]
CLIENT_PASSWORD = ENV["SERVICE_NOW_CLIENT_PASSWORD"]
REDIRECT_URI = ENV["SERVICE_NOW_REDIRECT_URI"]

BS_CREATE_INCIDENT_API_PATH = 'api/beme2/bsg_redcanary_inc_api/createINC'.freeze
BS_GET_INCIDENT_API_PATH = 'api/beme2/bsg_redcanary_inc_api/getINC'.freeze
INCIDENT_API_PATH = '/api/now/table/incident'.freeze
USER_API_PATH = '/api/now/table/sys_user'.freeze
INCIDENT_API_COMMENT_PATH = '/api/now/table/sys_journal_field'.freeze
INCIDENT_FIELD_PATH = '/api/now/table/sys_history_line'.freeze 
USER_AGENT = 'RWRMDR/0.0.1'.freeze

def incident_body
  {
    short_description: "[THREAT-6] Malicious Software (Coinminer and Credential Theft) affecting bergstrom-nikolaus.orn.name"
  }
end

def oauth_authorization_code_body
  {
    grant_type: "password",
    client_id: CLIENT_ID,
    client_secret: CLIENT_PASSWORD,
    username: USERNAME,
    password: PASSWORD
  }
end

def service_now_client
  client = Faraday.new(SERVICE_NOW_BASE_URL, headers: { 'User-Agent' => USER_AGENT }) do |b|
    b.request  :json
    b.response :json

    b.use Faraday::Response::RaiseError # compatibility with existing error handling strat
    b.request :basic_auth, USERNAME, PASSWORD

  end

  client
end

def service_now_client_oauth(token:)

  client = Faraday.new(SERVICE_NOW_BASE_URL, headers: { 'User-Agent' => USER_AGENT }) do |b|
    b.request  :json
    b.response :json

    b.authorization :Bearer, token
    b.adapter Faraday.default_adapter

    b.use Faraday::Response::RaiseError
  end

end

def get_incident(incident_num:)
  puts "Incident Num: #{incident_num}"
  response = service_now_client.get("#{INCIDENT_API_PATH}/#{incident_num}")
  response
end

def get_incident_oauth(incident_num:, token:)
  response = service_now_client_oauth(token: token).get("#{INCIDENT_API_PATH}/#{incident_num}")
  response
end

def get_incident_bs(number:, correlation_id:, token:)
  response = service_now_client_oauth(token: token).get("#{BS_GET_INCIDENT_API_PATH}?number=#{number}&correlation_id=#{correlation_id}")
  response
end

def get_all_incidents
  response = service_now_client.get(INCIDENT_API_PATH)
  response.body
end

def get_all_incidents_oauth(token:)
  # response = service_now_client.get(INCIDENT_API_PATH)
  response = service_now_client_oauth(token: token).get("#{INCIDENT_API_PATH}")
  response.body
end

def get_field_names(token:)
  tablename = 'incident'
  meta_url = "/api/now/ui/meta/#{tablename}"
  response = service_now_client_oauth(token: token).get(meta_url)
  response.body
end

def get_comments(incident_num:)
  response = service_now_client.get("#{INCIDENT_API_COMMENT_PATH}?sysparm_query=element_id=#{incident_num}^element=comments")
  response.body
end

def get_field_changes(incident_num:)
  response = service_now_client.get("#{INCIDENT_FIELD_PATH}?sysparm_query=fieldINstate^set.id=#{incident_num}")
  response.body
end

def add_comment(incident_num:, comment:)
  comment_body = {
    comments: comment
  }
  service_now_client.patch("#{INCIDENT_API_PATH}/#{incident_num}", comment_body.to_json)

  # Get all comments for incident and return the last one
  comments = get_comments(incident_num: incident_num)["result"]
  sorted_list = comments.sort_by { |k| k["sys_created_on"]}
  sorted_list.last
end

def create_incident(token:)
  threat_num = rand(1..1000)
  request_body = {
    short_description: "RWR RC Test Incident #{threat_num}",
    description: "This is a test incident to exercise API 001",
    correlation_id: "##{threat_num}}",
    impact: rand(1..4),
    urgency: rand(1..4)
  }
  response = service_now_client_oauth(token: token).post(BS_CREATE_INCIDENT_API_PATH, request_body.to_json)
  response.body
end

def get_user(sys_id:)
  response = service_now_client.get("#{USER_API_PATH}/#{sys_id}")
  response.body
end

def get_oauth_token
  # First need to get an authorization code that can be used to retrieve the token
  snclient = Faraday.new(
    url: SERVICE_NOW_BASE_URL
  )

  response_auth = snclient.post("oauth_token.do") do |req|
    req.body = URI.encode_www_form(oauth_authorization_code_body)
  end

  access_token = JSON.parse(response_auth.body)["access_token"]

  access_token
end


# Main
if ARGV.empty?
  puts "Please enter a command to run"
  puts "Usage:"
  puts "  create_incident"
  puts "  get_incident <incident_number> <incident_correlation_id>"
  puts "  get_all_incidents"
  puts "  get_comments <incident_sys_id>"
  puts "  get_field_names"
  puts "  get_user <user_sys_id>"
  puts "  get_oauth_token"
  puts "  add_comment <incident_sys_id> <comment>"
else
  case ARGV[0]
  when 'create_incident'
    oauth_token = get_oauth_token
    incident = create_incident(token: oauth_token)
    puts "INCIDENT: #{incident}"
  when 'get_incident_bs'
    if ARGV[1].nil? || ARGV[2].nil?
      puts "Please enter an incident number and correlation id"
    else
      oauth_token = get_oauth_token
      # puts "TOKEN RESPONSE: #{token_response["access_token"]}"
      incident = get_incident_bs(number: ARGV[1], correlation_id: ARGV[2], token: oauth_token)
      puts "INCIDENT: #{incident.body.to_json}"
    end
  when 'get_all_incidents'
    token = get_oauth_token
    incidents = get_all_incidents_oauth(token: token)
    puts "#{incidents["result"].length} found: How many do you want to see?"
    num = STDIN.gets.chomp.to_i
    i = 0
    incidents['result'].each do |incident|
      if i < num
        puts "NUMBER: #{incident['number']} SYS_ID: #{incident['sys_id']}"
        i += 1
      else
        break
      end
    end
  when 'get_comments'
    if ARGV[1].nil?
      puts "Please enter an incident sys id"
    else
      comments = get_comments(incident_num: ARGV[1])
      puts "Incident Comments: #{comments.to_json}"
    end
  when 'get_field_changes'
    if ARGV[1].nil?
      puts "Please enter an incident sys id"
    else
      field_changes = get_field_changes(incident_num: ARGV[1])
      puts "Incident Field Changes: #{field_changes.to_json}"
    end
  when 'get_field_names'
    token = get_oauth_token
    field_names = get_field_names(token: token)
    puts "ALL FIELDS: #{field_names.to_json}"
    puts "FIELDS: #{field_names['result']['columns'].keys}"
  when 'get_user'
    if ARGV[1].nil?
      puts "Please enter a user sys id"
    else
      user = get_user(sys_id: ARGV[1])
      puts "User: #{user.to_json}"
    end
  when 'get_oauth_token'
    token_response = get_oauth_token
    puts "TOKEN: #{token_response}"
  when 'add_comment'
    if ARGV[1].nil?
      puts "Please enter an incident sys id"
    elsif ARGV[2].nil?
      puts "Please enter a comment"
    else
      resp = add_comment(incident_num: ARGV[1], comment: ARGV[2])
      puts "Add Comment Response: #{resp.to_json}"
    end
  when 'get_states'
    field_names = get_field_names
    field_names['result']['columns']['state']['choices'].each do |choice|
      puts "CHOICE: #{choice['label']}: #{choice['value']}"
    end
    # puts "FIELDS: #{field_names['result']['columns']['state']['choices'].keys}"
  end

end
