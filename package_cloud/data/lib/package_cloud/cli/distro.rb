module PackageCloud
  module CLI
    class Distro < Base
      desc "list package_type",
           "list available distros and versions for package_type"
      def list(package_type)
        distros = nil
        measurement = Benchmark.measure {
          distros = client.distributions[package_type]
        }
        $logger.debug("distro list request timing: #{measurement}")
        if distros
          puts "Listing distributions for #{package_type}:"
          distros.each do |distro|
            next if distro["index_name"] == "any"
            puts "\n    #{parse_display_name(distro["display_name"])} (#{distro["index_name"]}):\n\n"
            distro["versions"].each do |ver|
              puts "        #{parse_version_name(ver["display_name"])} (#{ver["index_name"]})"
            end
          end

          puts "\nIf you don't see your distribution or version here, email us at support@packagecloud.io."
        else
          puts "No distributions exist for #{package_type}.".color(:red)
          puts "That either means that we don't support #{package_type} or that it doesn't require a distribution/version."
          exit(1)
        end
      end

      private
        def parse_display_name(name)
          if name == "Enterprise Linux"
            "#{name} - Amazon Linux | CentOS | RedHat"
          else
            name
          end
        end
        def parse_version_name(name)
          if name == 'Enterprise Linux 5.0'
            "#{name} | CentOS 5"
          elsif name == 'Enterprise Linux 6.0'
            "#{name} | CentOS 6 | Amazon Linux"
          elsif name == 'Enterprise Linux 7.0'
            "#{name} | CentOS 7"
          else
            name
          end
        end
    end
  end
end
