require 'tempfile'

module PackageCloud
  class Repository < Object
    def initialize(attrs, config)
      @attrs = attrs
      @config = config
    end

    def parse_dsc(dsc_path, dist_id)
      file_data = File.new(dsc_path, 'rb')
      base_url = @config.base_url
      url = PackageCloud::Util.compute_url(base_url, paths["package_contents"])
      begin
        resp = RestClient::Request.execute(:method => 'post',
                                           :url => url,
                                           :timeout => nil,
                                           :payload => { :package => {:package_file      => file_data,
                                                                      :distro_version_id => dist_id}})
        resp = JSON.parse(resp)
        print "success!\n"
        resp["files"]
      rescue RestClient::UnprocessableEntity => e
        print "error:\n".color(:red)
        json = JSON.parse(e.response)
        json.each do |k,v|
          puts "\n\t#{k}: #{v.join(", ")}\n"
        end
        puts ""
        exit(1)
      end
    end

    def create_package(file_path, dist_id, files=nil, filetype=nil, coordinates=nil)
      file_data = File.new(file_path, 'rb')
      base_url = @config.base_url
      url = PackageCloud::Util.compute_url(base_url, paths["create_package"])
      params = { :package_file => file_data,
                 :distro_version_id => dist_id }

     if coordinates
       params.merge!(:coordinates => coordinates)
     end

      if filetype == "dsc"
        file_ios = files.inject([]) do |memo, f|
          memo << File.new(f, 'rb')
        end
        params.merge!({:source_files => file_ios})
      end

      RestClient::Request.execute(:method => 'post',
                                  :url => url,
                                  :timeout => nil,
                                  :payload => { :package =>  params })
      print "success!\n".color(:green)
    end

    def install_script(type)
      url = urls["install_script"].gsub(/:package_type/, type)

      # the URL we've obtained above already contains the correct tokens
      # because the install script URL uses a master token for access, not
      # your API token, so if we pass @config.base_url in to compute_url,
      # we'll end up generating a URL like: https://token:@https://token:@...
      # because @config.base_url has the url with the API token in it and url
      # has the url (lol) with the master token in it.
      #
      # so just pass url in here.
      url = PackageCloud::Util.compute_url(url, '')
      script = RestClient.get(url)

      # persist the script to a tempfile to make it easier to execute
      file = Tempfile.new('foo')
      file.write(script)
      file.close
      file
    end

    def create_gpg_key(file_path)
      file_data = File.new(file_path, 'rb')
      base_url = @config.base_url
      url = PackageCloud::Util.compute_url(@config.base_url, paths["gpg_keys"])
      params = { keydata: file_data }

      print "Attempting to upload key file #{file_path}... "

      begin
        RestClient::Request.execute(:method => 'post',
                                    :url => url,
                                    :timeout => nil,
                                    :payload => { :gpg_key => params })
      rescue RestClient::UnprocessableEntity => e
        print "error: ".color(:red)
        json = JSON.parse(e.response)
        puts json["error"]
        puts ""
        exit(1)
      end

      print "success!\n".color(:green)
    end

    def gpg_keys
      url = PackageCloud::Util.compute_url(@config.base_url, paths["gpg_keys"])
      attrs = JSON.parse(RestClient.get(url))
      attrs["gpg_keys"].map { |a| GpgKey.new(a, @config) }
    end

    def master_tokens
      url = PackageCloud::Util.compute_url(@config.base_url, paths["master_tokens"])
      attrs = JSON.parse(RestClient.get(url))
      attrs.map { |a| MasterToken.new(a, @config) }
    end

    def create_master_token(name)
      url = PackageCloud::Util.compute_url(@config.base_url, paths["create_master_token"])
      begin
        resp = RestClient.post(url, :master_token => {:name => name})
        resp = JSON.parse(resp)
      rescue RestClient::UnprocessableEntity => e
        print "error:\n".color(:red)
        json = JSON.parse(e.response)
        json.each do |k,v|
          puts "\n\t#{k}: #{v.join(", ")}\n"
        end
        puts ""
        exit(1)
      end
      resp
    end

    def promote(dist, package_name, dest_repo_name, scope=nil)
      begin
        url = PackageCloud::Util.compute_url(@config.base_url, paths["self"] + "/" + [dist, package_name, "promote.json"].compact.join("/"))
        resp = if scope
                 RestClient.post(url, destination: dest_repo_name, scope: scope)
               else
                 RestClient.post(url, destination: dest_repo_name)
               end
        resp = JSON.parse(resp)
      rescue RestClient::UnprocessableEntity, RestClient::ResourceNotFound => e
        print "error:\n".color(:red)
        json = JSON.parse(e.response)
        json.each do |k,v|
          puts "\n\t#{k}: #{v.join(", ")}\n"
        end
        puts ""
        exit(1)
      end
    end

    def yank(dist, package_name, scope=nil)
      begin
        url = PackageCloud::Util.compute_url(@config.base_url, paths["self"] + "/" + [dist, package_name].compact.join("/"))
        if scope
          RestClient.delete(url, params: { scope: scope })
        else
          RestClient.delete(url)
        end
      rescue RestClient::ResourceNotFound => e
        print "error:\n".color(:red)
        json = JSON.parse(e.response)
        json.each do |k,v|
          puts "\n\t#{k}: #{v.join(", ")}\n"
        end
        puts ""
        exit(1)
      end
    end

    def private_human
      send(:private) ? "private".color(:red) : "public".color(:green)
    end
  end
end
