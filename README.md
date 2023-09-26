# ServiceNow_ruby_api_wrapper
Thin ruby wrapper around ServiceNow REST API calls

## Setup
This app uses the dotenv gem to set environment via a .env file
Before running app create a `.env` file at the top level of the app with the following values set:
```
SERVICE_NOW_BASE_URL=https://<your_dev_instance>.service-now.com/
SERVICE_NOW_USERNAME=<your_dev_instance_username>
SERVICE_NOW_PASSWORD=<your_dev_instance_password>
SERVICE_NOW_CLIENT_ID=<your_sn_oauth_client_id>
SERVICE_NOW_CLIENT_PASSWORD=<your_sn_oauth_client_secret>
```

## Usage
Run ruby script on the command line  
```
ruby api_calls.rb <command> <inputs>
```

## Commands
```
get_incident <incident_sys_id>  
get_all_incidents  
get_comments <incident_sys_id>  
get_field_names  
create_incident [<key: value>, ...]  
get_user <user_sys_id>  
get_oauth_token
```
