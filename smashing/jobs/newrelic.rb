require 'net/http'
require 'json'
require 'time'
require "yaml"

puts 'Initializing newrelic widget...'
STDOUT.flush

newrelic_addr = 'api.newrelic.com'

newrelic_credentials = YAML.load_file("widgets/newrelic/newrelic.credentials")

newrelic_stat = Hash.new({ value: 0 })
newrelic_health = 'danger'

NEWRELIC_URI = URI.parse("https://" + newrelic_addr)

SCHEDULER.every '10s', :first_in => 0 do |job|
  http = Net::HTTP.new(NEWRELIC_URI.host, NEWRELIC_URI.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new("/v2/applications.json")

  request["X-Api-Key"] = newrelic_credentials["newrelic_rest_api_key"]

  begin
    response = http.request(request)
    response_json = JSON.parse(response.body)

    if response_json.has_key? "applications"
      newrelic_stat["name"] = { label: "name", value: response_json["applications"][0]["name"] }
    end

    send_event('newrelic', { items: newrelic_stat.values })

    newrelic_health = "ok"

    send_event('newrelic', { newrelicHealth: newrelic_health })
  rescue SystemCallError
    newrelic_health = "danger"

    send_event('newrelic', { newrelicHealth: newrelic_health })
  end

end
