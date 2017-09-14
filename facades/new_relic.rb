require "rest-client"
require "active_support/core_ext"

class NewRelic
  attr_reader :uptime,
              :total_requests,
              :requests_per_minute,
              :average_response_time,
              :request_satisfaction,
              :error_rate,
              :time_frame

  def initialize
    @_api_key ||= ENV["NEW_RELIC_API_KEY"]
    @_app_id ||= ENV["NEW_RELIC_APP_ID"]
  end

  def uptime(months_ago)
    response = RestClient.
      get("#{api_url}names[]=Errors/all&values[]=error_count&#{time_frame(months_ago)}&summarize=true", headers={ "x-api-key": api_key })

    response.body
  end

  def total_requests(months_ago)
    requests_per_minute(months_ago) * minutes_in_the_month(months_ago)
  end

  def total_requests_formatted(months_ago)
    (total_requests(months_ago) / 1000).floor
  end

  def requests_per_minute(months_ago)
    response = RestClient.
      get("#{api_url}names[]=Agent/MetricsReported/count&#{time_frame(months_ago)}&summarize=true", headers={ "x-api-key": api_key })

    parse(response)[:metric_data][:metrics][0][:timeslices][0][:values][:requests_per_minute]
  end

  def error_count(months_ago)
    response = RestClient.
      get("#{api_url}names[]=Errors/all&#{time_frame(months_ago)}&summarize=true", headers={ "x-api-key": api_key })

    parse(response)[:metric_data][:metrics][0][:timeslices][0][:values][:error_count]
  end

  def error_rate(months_ago)
    "%.2f" % ((100 * error_count(months_ago)) / total_requests(months_ago))
  end

  def average_response_time(months_ago)
    response = RestClient.
      get("#{api_url}names[]=HttpDispatcher&values[]=average_response_time&#{time_frame(months_ago)}&summarize=true", headers={ "x-api-key": api_key })

    parse(response)[:metric_data][:metrics][0][:timeslices][0][:values][:average_response_time]
  end

  def request_satisfaction(months_ago)
    response = RestClient.
      get("#{api_url}names[]=Apdex&names[]=EndUser/Apdex&values[]=score&#{time_frame(months_ago)}&summarize=true", headers={ "x-api-key": api_key })

    parse(response)[:metric_data][:metrics][0][:timeslices][0][:values][:score] * 100
  end

  def time_frame(months_ago)
    date = Time.now.utc
    start_date, end_date = ""

    case months_ago
      when 2
        start_date = date.prev_month.prev_month.beginning_of_month
        end_date = date.prev_month.prev_month.end_of_month
      when 1
        start_date = date.prev_month.beginning_of_month
        end_date = date.prev_month.end_of_month
      when 0
        start_date = date.beginning_of_month
        end_date = date
    end

    start_date = start_date.iso8601.delete("Z")
    end_date = end_date.iso8601.delete("Z")
  end

  private
  def api_key
    @_api_key
  end

  def app_id
    @_app_id
  end

  def api_url
    "https://api.newrelic.com/v2/applications/" + app_id + "/metrics/data.json?"
  end

  def minutes_in_the_month(months_ago)
    case months_ago
      when 2
        Time.days_in_month(Time.now.prev_month.prev_month.month, Time.now.prev_month.prev_month.year) * 24 * 60
      when 1
        Time.days_in_month(Time.now.prev_month.month, Time.now.prev_month.year) * 24 * 60
      when 0
        ((Time.now - Time.now.beginning_of_month) / 60)
    end
  end

  def parse(response)
    JSON.parse(response.body, symbolize_names: true)
  end
end
