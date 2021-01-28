module PackageCloud
  class GpgKey < Object
    def initialize(attrs, config)
      @attrs = attrs
      @config = config
    end

    def destroy
      url = PackageCloud::Util.compute_url(@config.base_url, @attrs["self"])
      RestClient.delete(url)
    end
  end
end
