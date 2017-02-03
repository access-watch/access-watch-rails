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
        request: {
          protocol: request.headers["Version"],
          method: request.method,
          scheme: URI(request.original_url).scheme,
          host: request.host,
          port: request.port,
          url: request.original_fullpath,
          headers: extract_http_headers(request.headers)
        },
        response: {status: response.status},
        context: {memory_usage: memory_usage_in_bytes},
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

    def memory_usage_in_bytes
      linux_process_memory_usage_in_bytes(Process.pid)
    end

    def linux_process_status(pid)
      path = "/proc/#{pid}/status"
      return unless File.readable?(path)
      File.read(path).split("\n").reduce({}) do |hash, line|
        name, value = line.split(":")
        hash[name] = value.strip
        hash
      end
    end

    MEMORY_CONVERSIONS = {"kb" => 1024, "mb" => 1024 * 1024, "gb" => 1024 * 1024 * 1024}

    def linux_process_memory_usage_in_bytes(pid)
      return unless status = linux_process_status(pid)
      value, unit = status["VmRSS"].split
      value.to_i * MEMORY_CONVERSIONS[unit.downcase]
    end
  end
end
