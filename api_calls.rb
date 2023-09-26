#!/usr/bin/env ruby
require 'faraday'
require 'pry'
require 'json'

SERVICE_NOW_BASE_URL = 'https://dev180394.service-now.com/'.freeze
USERNAME = 'admin'.freeze
PASSWORD = "Piglet.4life".freeze
CLIENT_ID = "40af3e30ffa13550797f75b72bf7eaf3".freeze
CLIENT_PASSWORD = "password123".freeze

INCIDENT_API_PATH = '/api/now/table/incident'.freeze
USER_API_PATH = '/api/now/table/sys_user'.freeze
INCIDENT_API_COMMENT_PATH = '/api/now/table/sys_journal_field'.freeze
USER_AGENT = 'RWRMDR/0.0.1'.freeze

def incident_body
  {
    short_description: "[THREAT-6] Malicious Software (Coinminer and Credential Theft) affecting bergstrom-nikolaus.orn.name"
  }
end

def oauth_body
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

    b.use Faraday::Response::RaiseError # compatibility with existing error handling strat
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

def get_all_incidents
  response = service_now_client.get(INCIDENT_API_PATH)
  response.body
end

def get_field_names
  tablename = 'incident'
  meta_url = "/api/now/ui/meta/#{tablename}"
  response = service_now_client.get(meta_url)
  response.body
end

def get_comments(incident_num:)
  response = service_now_client.get("#{INCIDENT_API_COMMENT_PATH}?sysparm_query=element_id=#{incident_num}^element=comments")
  response.body
end

def create_incident(incident_body:)
  response = service_now_client.post(INCIDENT_API_PATH, incident_body.to_json)
  response.body
end

def get_user(sys_id:)
  response = service_now_client.get("#{USER_API_PATH}/#{sys_id}")
  response.body
end

def get_oauth_token
  snclient = Faraday.new(
    url: SERVICE_NOW_BASE_URL
  )

  response = snclient.post("oauth_token.do") do |req|
    req.body = URI.encode_www_form(oauth_body)
  end

  response.body
end


# new_incident = {
#   short_description: "This is my #{rand(1000)}th incident and boy am I getting tired of this.",
#   assignment_group: '287ebd7da9fe198100f92cc8d1d2154e',
#   urgency: '2',
#   impact: '2',
# }

# customFields = {"0"=>{"title"=>"x_1115365_rwr_te_0_foo", "value"=>"Lorem Ipsum Grande Latte"},"1"=>{"title"=>"x_1115365_rwr_te_0_piglet", "value"=>"stays"}}

# incident_fields = {}

# customFields.values.each do |cf|
#   new_incident[cf['title'].to_sym] = cf['value']
# end

# binding.pry

# create_response = create_incident(incident_body: new_incident)

# puts "CREATE RESPONSE: #{create_response}"

# new_incident_number = create_response['result']['number']

if ARGV.empty?
  puts "Please enter a command to run"
  puts "Usage:"
  puts "  get_incident <incident_sys_id>"
  puts "  get_all_incidents"
  puts "  get_comments <incident_sys_id>"
  puts "  get_field_names"
  puts "  create_incident [1..n] <key: value>"
  puts "  get_user <user_sys_id>"
  puts "  get_oauth_token"
else
  case ARGV[0]
  when 'get_incident'
    if ARGV[1].nil?
      puts "Please enter an incident sys id"
    else
      token_response = JSON.parse(get_oauth_token)
      # puts "TOKEN RESPONSE: #{token_response["access_token"]}"
      incident = get_incident_oauth(incident_num: ARGV[1], token: token_response["access_token"])
      puts "INCIDENT: #{incident.body.to_json}"
    end
  when 'get_all_incidents'
    incidents = get_all_incidents
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
  when 'get_field_names'
    field_names = get_field_names
    puts "FIELDS: #{field_names['result']['columns'].keys}"
  when 'create_incident'
    puts "CREATE INCIDENT NOT QUITE SUPPORTED YET"
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
  end
end