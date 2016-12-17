module Rollbar
  module Dumps
    module Configuration
      extend self

      def access_token
        ENV['ROLLBAR_ACCESS_TOKEN']
      end

      def endpoint
        'https://api.rollbar.com/api/1/item/'
      end
    end
  end
end
