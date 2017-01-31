module AccessWatch
  class Logger
    attr_reader :client

    def initialize(config)
      @client = AccessWatch::Client.new(config)
    end

    def record(request, response)
      post_request(
        time: Time.now.utc,
        address: request.remote_ip,
        host: request.host,
        request: {
          # TODO: Check if is SERVER_PROTOCOL comes from client browser
          # "protocol": "HTTP/1.1",
          method: request.method,
          scheme: URI(request.original_url).scheme,
          host: request.host,
          port: request.port,
          url: request.original_fullpath,
          headers: extract_http_headers(request.headers)
        },
        response: {status: response.status},
      )
    end

    def extract_http_headers(headers)
      headers.reduce({}) do |hash, (name, value)|
        if name.index("HTTP_") == 0 && name != "HTTP_COOKIE"
          hash[format_header_name(name)] = value
        end
        hash
      end
    end

    def format_header_name(name)
      name.sub(/^HTTP_/, '').sub("_", " ").titleize.sub(" ", "-")
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
  end
end
