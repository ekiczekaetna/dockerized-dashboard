require 'net/http'
require 'json'
require 'time'
require "yaml"

puts 'Initializing sumologic widget...'
STDOUT.flush

sumologic_addr = 'api.us2.sumologic.com'

sumologic_credentials = YAML.load_file("widgets/sumologic/sumologic.credentials")

sumologic_stat = Hash.new({ value: 0 })
sumologic_health = 'danger'

SUMOLOGIC_URI = URI.parse("https://" + sumologic_addr)

SCHEDULER.every '10s', :first_in => 0 do |job|
  http = Net::HTTP.new(SUMOLOGIC_URI.host, SUMOLOGIC_URI.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new("/api/v1/logs/search?q=kubernetes&limit=1")

  request.basic_auth(sumologic_credentials["sumologic_access_id"], sumologic_credentials["sumologic_access_key"])

  begin
    response = http.request(request)
    response_json = JSON.parse(response.body)

    if response_json.kind_of?(Array)
      if response_json[0].has_key? "_sourcecategory"
        sumologic_stat["_sourcecategory"] = { label: "_sourcecategory", value: response_json[0]["_sourcecategory"] }
        sumologic_stat["_messagetime"] = { label: "_messagetime", value: Time.at(response_json[0]["_messagetime"]/1000) }
        sumologic_stat["_sourcename"] = { label: "_sourcename", value: response_json[0]["_sourcename"] }
      end
    end

    send_event('sumologic', { items: sumologic_stat.values })

    sumologic_health = "ok"

    send_event('sumologic', { sumologicHealth: sumologic_health })
  rescue SystemCallError
    sumologic_health = "danger"

    send_event('sumologic', { sumologicHealth: sumologic_health })
  end

end
