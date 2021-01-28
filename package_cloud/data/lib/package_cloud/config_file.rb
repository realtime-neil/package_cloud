require "highline/import"
require "json"
require "uri"
require "cgi"

module PackageCloud
  class ConfigFile
    attr_reader :token

    def initialize(filename = "~/.packagecloud", url = "https://packagecloud.io")
      handle_locale
      @filename = File.expand_path(filename)
      @url = URI(url)
    end

    def read_or_create
      if ENV["PACKAGECLOUD_TOKEN"]
        if ENV["PACKAGECLOUD_TOKEN"].length < 48
          puts "Found PACKAGECLOUD_TOKEN environment variable but is empty or too short! Visit https://packagecloud.io/api_token and confirm it is correct."
          exit!
        end
        @token = ENV["PACKAGECLOUD_TOKEN"]
        @url   = URI(ENV["PACKAGECLOUD_URL"]) if ENV["PACKAGECLOUD_URL"]
        output_host_and_token
      elsif File.exist?(@filename)
        attrs = JSON.parse(File.read(@filename))
        @token = attrs["token"] if attrs.has_key?("token")
        @url   = URI(attrs["url"]) if attrs.has_key?("url")
        fix_config_file!
        output_host_and_token
      else
        puts "No config file exists at #{@filename}. Login to create one."

        @token = login_from_console
        print "Got your token. Writing a config file to #{@filename}... "
        write
        puts "success!"
      end
    end

    def url
      @url ||= URI("https://packagecloud.io")
    end

    def base_url(username = token, password = "")
      u = url.dup
      u.user = CGI.escape(username)
      u.password = CGI.escape(password)
      u.to_s
    end

    private
      def handle_locale
        # Force the external encoding to be UTF-8 on windows and everywhere
        # else. This will somtimes fail on windows because it seems the default
        # windows encoding on windows is IBM 437 and it
        # is very painful to change to UTF-8. The failure in this case will
        # just be 1 "?" being printed per character that isn't
        # representable.
        Encoding.default_external = 'UTF-8'
      end

      def login_from_console
        e     = ask("Email:")
        p     = ask("Password:") { |q| q.echo = false }

        begin
          PackageCloud::Auth.get_token(base_url(e, p))
        rescue RestClient::Unauthorized => e
          puts "Sorry, but we couldn't find you. Give it another try."
          login_from_console
        end
      end

      def write
        attrs = {:url => url.to_s, :token => @token}
        File.open(@filename, "w", 0600) { |f| f << JSON.dump(attrs); f << "\r\n" }
      end

      def output_host_and_token
        token = @token[-4..-1].rjust(10, '*')
        puts "Using #{@url} with token:#{token}"
      end

      ## package_cloud versions prior to 0.2.17 have a bug in the
      ## config where the url is used verbatim as the key, instead of "url",
      ## this attempts to fix the config file
      def fix_config_file!
        if File.exists?(@filename) && File.writable?(@filename)
          attrs = JSON.parse(File.read(@filename))
          if !attrs.has_key?("url")
            ## overwrite the config file if "url" key not found
            write
          end
        end
      end

  end
end
