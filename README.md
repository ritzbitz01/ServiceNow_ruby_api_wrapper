# ServiceNow_ruby_api_wrapper
Thin ruby wrapper around ServiceNow REST API calls

# Usage
Run ruby script on the command line
ruby api_calls.rb <command> <inputs>

## Commands
get_incident <incident_sys_id>
get_all_incidents
get_comments <incident_sys_id>
get_field_names
create_incident [<key: value>, ...]
get_user <user_sys_id>
get_oauth_token
