module AccessWatch
  class RackLogger
    attr_reader :app, :client

    def initialize(app, config)
      @app, @client = app, AccessWatch::Client.new(config)
    end

    def call(env)
      started_at = Time.now.utc
      status, headers, body = app.call(env)
      record(env, status, started_at, Time.now.utc)
      [status, headers, body]
    end

    def record(env, status, started_at, finished_at)
      post_request(
        time: started_at.iso8601(3),
        address: env["REMOTE_ADDR"],
        request: {
          protocol: env["HTTP_VERSION"],
          method: env["REQUEST_METHOD"],
          scheme: env["rack.url_scheme"],
          host: env["HTTP_HOST"],
          port: env["SERVER_PORT"],
          url: env["ORIGINAL_FULLPATH"],
          headers: extract_http_headers(env),
        },
        response: {status: status},
        context: {
          execution_time: finished_at - started_at,
          memory_usage: memory_usage_in_bytes,
        },
      )
    end

    #######################
    ### Private methods ###
    #######################

    private

    def extract_http_headers(headers)
      headers.reduce({}) do |hash, (name, value)|
        if name.index("HTTP_") == 0 && name != "HTTP_COOKIE"
          hash[format_header_name(name)] = value
        end
        hash
      end
    end

    def format_header_name(name)
      name.sub(/^HTTP_/, '').gsub("_", " ").titleize.gsub(" ", "-")
    end

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
