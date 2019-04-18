require 'net/http'
require 'json'
require 'time'
require "yaml"

puts 'Initializing rally widget...'
STDOUT.flush

rally_addr = 'rally1.rallydev.com'
rally_project_key = '240924107340'

rally_credentials = YAML.load_file("widgets/rally/rally.credentials")

rally_stat = Hash.new({ value: 0 })
rally_health = 'danger'

RALLY_URI = URI.parse("https://" + rally_addr)

SCHEDULER.every '10s', :first_in => 0 do |job|
  http = Net::HTTP.new(RALLY_URI.host, RALLY_URI.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new("/slm/webservice/v2.0/project/" + rally_project_key)

  request.basic_auth(rally_credentials["rally_username"], rally_credentials["rally_password"])

  begin
    response = http.request(request)
    response_json = JSON.parse(response.body)

    if response_json.has_key? "Project"
      rally_stat["project"] = { label: "Project", value: response_json["Project"]["_refObjectName"] }
    end

    send_event('rally', { items: rally_stat.values })

    rally_health = "ok"

    send_event('rally', { rallyHealth: rally_health })
  rescue SystemCallError
    rally_health = "danger"

    send_event('rally', { rallyHealth: rally_health })
  end

end
