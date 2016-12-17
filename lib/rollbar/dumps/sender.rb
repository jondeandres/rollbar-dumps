require 'net/http'
require 'json'

require 'rollbar/dumps/configuration'

module Rollbar
  module Dumps
    class Sender
      def send(body)
        uri = URI.parse(Configuration.endpoint)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.request_uri)

        request.body = JSON.dump(body)
        request.add_field('X-Rollbar-Access-Token', Configuration.access_token)

        puts http.request(request)
      end
    end
  end
end
