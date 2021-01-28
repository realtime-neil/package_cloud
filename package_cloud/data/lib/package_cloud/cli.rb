require "thor"
require "logger"
require "benchmark"

module PackageCloud
  module CLI
    autoload :Distro,      "package_cloud/cli/distro"
    autoload :Entry,       "package_cloud/cli/entry"
    autoload :MasterToken, "package_cloud/cli/master_token"
    autoload :ReadToken,   "package_cloud/cli/read_token"
    autoload :Repository,  "package_cloud/cli/repository"
    autoload :GpgKey,      "package_cloud/cli/gpg_key"

    class Base < Thor
      class_option "config", :desc => "Specify a path to config file containing your API token and URL; default is ~/.packagecloud"
      class_option "url", :desc => "Specify the website URL to use; default is https://packagecloud.io. Useful for packagecloud:enterprise users."
      class_option "verbose", :type => :boolean, :desc => "Enable verbose mode."

      private
        def get_valid(prompt)
          selection = ""
          times = 0
          until yield(selection)
            if times > 0
              puts "#{selection} is not a valid selection."
            end
            print "#{prompt}: "
            selection = ::Kernel.gets.chomp
            times += 1
          end

          selection
        end

        def config
          $logger = ::Logger.new(STDOUT)
          $verbose = !!options[:verbose]
          if $verbose
            $logger.level = ::Logger::DEBUG
            $logger.debug("verbose mode enabled")
          else
            $logger.level = ::Logger::WARN
          end
          @config ||= begin
            ConfigFile.new(options[:config] || "~/.packagecloud",
                         options[:url] || "https://packagecloud.io").tap(&:read_or_create)
                      end
        end

        def client
          @client ||= Client.new(config)
        end
    end
  end
end
