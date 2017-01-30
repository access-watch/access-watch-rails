module AccessWatch
  class Logger
    attr_reader :client

    def initialize(config)
      @client = Client.new(config)
      @parameter_filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
      ActiveSupport::Notifications.subscribe("process_action.action_controller", &method(:after_http_request))
    end

    def after_http_request(name, start, finish, id, payload)
      request = payload[:headers].instance_variable_get(:@req)
      post_request(
        time: start,
        address: request.remote_ip,
        host: request.host,
        request: {
          # TODO: Check if is SERVER_PROTOCOL comes from client browser
          # "protocol": "HTTP/1.1",
          method: payload[:method],
          scheme: URI(request.original_url).scheme,
          host: request.host,
          port: request.port,
          url: payload[:path],
          headers: extract_headers(payload)
        },
        response: {status: payload[:status]},
      )
    end

    #######################
    ### Private methods ###
    #######################

    private

    def post_request(data)
      post_async("log".freeze, data)
    end

    def post_async(path, data)
      Thread.new { client.post(path, data) }
    end

    def filter_sensitive_data(hash)
      @parameter_filter ? @parameter_filter.filter(hash) : hash
    end

    def filter_environment_variables(hash)
      hash.clone.keep_if { |key,value| key == key.upcase }
    end

    def extract_headers(payload)
      filter_sensitive_data(filter_environment_variables(payload[:headers].env))
    end
  end
end
