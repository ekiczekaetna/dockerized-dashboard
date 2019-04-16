require 'net/http'
require 'json'
require 'time'

puts 'Initializing sonar widget...'
STDOUT.flush

bridge_network_sq_ip = '172.17.0.1'

sonar_stat = Hash.new({ value: 0 })

SONAR_URI = URI.parse("http://" + bridge_network_sq_ip + ":9000")
SONAR_AUTH = {
'name' => 'admin',
'password' => 'admin'
}

SCHEDULER.every '15s', :first_in => 0 do |job|
  http = Net::HTTP.new(SONAR_URI.host, SONAR_URI.port)

  request = Net::HTTP::Get.new("/api/system/health")
  if SONAR_AUTH['name']
      request.basic_auth(SONAR_AUTH['name'], SONAR_AUTH['password'])
  end
  response = http.request(request)
  response_json = JSON.parse(response.body)

  sonar_stat["health"] = { label: "Health", value: response_json["health"] }

  send_event('sonar', { items: sonar_stat.values })
end
