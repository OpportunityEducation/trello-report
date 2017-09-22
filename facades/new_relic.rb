require "rest-client"
require "active_support/core_ext"

class NewRelic
  attr_reader :month, :year
#
  def initialize(year, month)
    @year = year
    @month = month
  end

  def uptime
    puts "does not exist"
  end

  def total_requests_formatted
    (total_requests / 1000).floor
  end

  def requests_per_minute
    url = "#{api_url}names[]=HttpDispatcher&#{time_frame}&summarize=true"
    response = get(url)

    @requests_per_minute ||= response.metric_data.metrics[0].timeslices[0].values.requests_per_minute
  end

  def error_rate
    "%.2f" % (100 * error_count / (total_requests + other_transactions_count))
  end

  def average_response_time
    url = "#{api_url}names[]=HttpDispatcher&values[]=average_response_time&#{time_frame}&summarize=true"
    response = get(url)

    response.metric_data.metrics[0].timeslices[0].values.average_response_time
  end

  def request_satisfaction
    url = "#{api_url}names[]=Apdex&names[]=EndUser/Apdex&values[]=score&#{time_frame}&summarize=true"
    response = get(url)

    response.metric_data.metrics[0].timeslices[0].values.score * 100
  end

  private
  def api_key
    ENV["NEW_RELIC_API_KEY"]
  end

  def app_id
    ENV["NEW_RELIC_APP_ID"]
  end

  def api_url
    "https://api.newrelic.com/v2/applications/#{app_id}/metrics/data.json?"
  end

  def get(url)
    JSON.parse(RestClient.get(url, headers={"x-api-key": api_key}).body, object_class: OpenStruct)
  end

  def start_time
    Time.new(year, month).utc.at_beginning_of_month
  end

  def end_time
    end_time = ''

    if Time.now.month == month && Time.now.year == year
      end_time = Time.now.utc
    else
      end_time = Time.new(year, month).utc.at_end_of_month
    end

    end_time
  end

  def time_frame
    formatted_start_time = start_time.iso8601.gsub("Z", '+00:00')
    formatted_end_time = end_time.iso8601.gsub("Z", '+00:00')

    "from=#{formatted_start_time}&to=#{formatted_end_time}"
  end

  def other_transactions_count
    url = "#{api_url}names[]=OtherTransaction/all&#{time_frame}&summarize=true"
    response = get(url)

    response.metric_data.metrics[0].timeslices[0].values.call_count
  end

  def error_count
    url ="#{api_url}names[]=Errors/all&#{time_frame}&summarize=true"
    response = get(url)

    response.metric_data.metrics[0].timeslices[0].values.error_count
  end

  def total_requests
    @total_requests ||= begin
      url = "#{api_url}names[]=HttpDispatcher&#{time_frame}&summarize=true"
      response = get(url)
      response.metric_data.metrics[0].timeslices[0].values.call_count
    end
  end
end
