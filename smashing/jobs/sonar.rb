require 'net/http'
require 'json'
require 'time'

puts 'Initializing sonar widget...'
STDOUT.flush

bridge_network_sq_ip = '172.17.0.1'
sq_project_key = 'project_key'

sonar_stat = Hash.new({ value: 0 })
sonar_health = 'danger'

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

  begin
    response = http.request(request)
    response_json = JSON.parse(response.body)

    case response_json["health"]
    when "GREEN"
      sonar_health = "ok"
    when "RED"
      sonar_health = "danger"
    when "YELLOW"
      sonar_health = "warning"
    else
      sonar_health = "danger"
    end
  rescue SystemCallError
    sonar_health = "danger"
  end

  send_event('sonar', { sonarHealth: sonar_health })

end

SCHEDULER.every '10s', :first_in => 0 do |job|
  http = Net::HTTP.new(SONAR_URI.host, SONAR_URI.port)

  request = Net::HTTP::Get.new("/api/measures/component?componentKey=" + sq_project_key + "&metricKeys=ncloc,code_smells,coverage,tests")

  if SONAR_AUTH['name']
      request.basic_auth(SONAR_AUTH['name'], SONAR_AUTH['password'])
  end

  begin
    response = http.request(request)
    response_json = JSON.parse(response.body)

    if response_json.has_key? "component"
      for sonar_metric_kv_pair in response_json["component"]["measures"] do
        case sonar_metric_kv_pair["metric"]
        when "tests"
          sonar_stat["tests"] = { label: "Unit Tests", value: sonar_metric_kv_pair["value"] }
        when "ncloc"
          sonar_stat["ncloc"] = { label: "Non-commenting LoC", value: sonar_metric_kv_pair["value"] }
        when "code_smells"
          sonar_stat["code_smells"] = { label: "Code Smells", value: sonar_metric_kv_pair["value"] }
        when "coverage"
          sonar_stat["coverage"] = { label: "Coverage", value: '%.0f' % (sonar_metric_kv_pair["value"].to_f * 100.0) + "%"}
        end
      end
    end

    send_event('sonar', { items: sonar_stat.values })
  rescue SystemCallError
    sonar_health = "danger"

    send_event('sonar', { sonarHealth: sonar_health })
  end

end
