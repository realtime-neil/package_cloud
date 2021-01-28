require "rest_client"
require "json"

module PackageCloud
  module Auth
    class << self
      def get_token(url)
        url = PackageCloud::Util.compute_url(url, "/api/v1/token.json")
        JSON.parse(RestClient.get(url))["token"]
      end
    end
  end
end
