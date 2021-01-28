require 'open-uri'

module PackageCloud
  class Util
    class << self
      def compute_url(base_url, path)
        url = base_url + path
        proxy_uri = URI.parse(url).find_proxy()
        if proxy_uri
          RestClient.proxy = proxy_uri.to_s
        end

        url
      end
    end
  end
end
