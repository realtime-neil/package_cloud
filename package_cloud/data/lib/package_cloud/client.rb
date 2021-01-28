require "json"
require "rest_client"

module PackageCloud
  class Client
    def initialize(config)
      @config = config
    end

    def repositories
      url = PackageCloud::Util.compute_url(@config.base_url, "/api/v1/repos.json")
      begin
        attrs = JSON.parse(RestClient.get(url))
        attrs.map { |a| Repository.new(a, @config) }
      rescue RestClient::ResourceNotFound => e
        print "failed!\n".color(:red)
        exit(127)
      end
    end

    def repository(name)
      user, repo = name.split("/")
      url = PackageCloud::Util.compute_url(@config.base_url, "/api/v1/repos/#{user}/#{repo}.json")
      begin
        attrs = JSON.parse(RestClient.get(url))
        if attrs["error"] == "not_found"
          print "failed... Repository #{user}/#{repo} not found!\n".color(:red)
          exit(127)
        end

        Repository.new(attrs, @config)
      rescue RestClient::ResourceNotFound => e
        print "failed!\n".color(:red)
        exit(127)
      end
    end

    def create_repo(name, priv)
      url = PackageCloud::Util.compute_url(@config.base_url, "/api/v1/repos.json")
      begin
        JSON.parse(RestClient.post(url, :repository => {:name => name, :private => priv == "private" ? "1" : "0"}))
      rescue RestClient::UnprocessableEntity => e
        print "error!\n".color(:red)
        json = JSON.parse(e.response)
        json.each do |k,v|
          puts "\n\t#{k}: #{v.join(", ")}\n"
        end
        puts ""
        exit(1)
      end
    end

    def distributions
      url = PackageCloud::Util.compute_url(@config.base_url, "/api/v1/distributions.json")
      begin
        JSON.parse(RestClient.get(url))
      rescue RestClient::ResourceNotFound => e
        print "failed!\n".color(:red)
        exit(127)
      end
    end

  end
end
