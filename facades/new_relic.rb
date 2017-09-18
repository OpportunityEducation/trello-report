require "rest-client"
require "active_support/core_ext"

class NewRelic
  attr_reader :start_time, :end_time, :minutes_in_the_month, :month, :year, :time_frame
#
  def initialize(args)
    @_api_key ||= ENV["NEW_RELIC_API_KEY"]
    @_app_id ||= ENV["NEW_RELIC_APP_ID"]
    @month = args.month
    @year = args.year
    @start_time = get_start_time
    @end_time = get_end_time
    @time_frame = get_formatted_time_frame
    @minutes_in_the_month = in_current_month ? ((Time.now - Time.now.beginning_of_month) / 60) : Time.days_in_month(args.month, args.year)
  end

  def uptime
    puts "does not exist"
  end

  def total_requests
    requests_per_minute * minutes_in_the_month
  end

  def total_requests_formatted
    (total_requests / 1000).floor
  end

  def requests_per_minute
    url = "#{api_url}names[]=Agent/MetricsReported/count&#{time_frame}&summarize=true"
    response = get(url)

    parse(response).metric_data.metrics[0].timeslices[0].values.requests_per_minute
  end

  def error_count
    url ="#{api_url}names[]=Errors/all&#{time_frame}&summarize=true"
    response = get(url)

    parse(response).metric_data.metrics[0].timeslices[0].values.error_count
  end

  def error_rate
    "%.2f" % ((100 * error_count) / total_requests)
  end

  def average_response_time
    url = "#{api_url}names[]=HttpDispatcher&values[]=average_response_time&#{time_frame}&summarize=true"
    response = get(url)

    parse(response).metric_data.metrics[0].timeslices[0].values.average_response_time
  end

  def request_satisfaction
    url = "#{api_url}names[]=Apdex&names[]=EndUser/Apdex&values[]=score&#{time_frame}&summarize=true"
    response = get(url)

    parse(response).metric_data.metrics[0].timeslices[0].values.score * 100
  end

  def get_formatted_time_frame
    formatted_start_time = start_time.iso8601.gsub("Z", '+00:00')
    formatted_end_time = end_time.iso8601.gsub("Z", '+00:00')

    "from=#{formatted_start_time}&to=#{formatted_end_time}"
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

  def get(url)
    RestClient.get(url, headers={"x-api-key": api_key})
  end

  def parse(response)
    JSON.parse(response.body, object_class: OpenStruct)
  end


  def get_minutes_in_the_month
    in_current_month ? ((Time.now - Time.now.beginning_of_month) / 60) : (Time.days_in_month(month, year) * 24 * 60)
  end

  def get_start_time
    Time.new(year, month).at_beginning_of_month.utc
  end

  def get_end_time
    if in_current_month
      Time.now.utc
    else
      Time.new(year, month).at_end_of_month.utc
    end
  end

  def in_current_month
    Time.now.month == month && Time.now.year == year
  end
end
