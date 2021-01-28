module PackageCloud
  module CLI
    class GpgKey < Base
      desc "list user/repository",
           "list all GPG keys for specified repository"
      def list(repo_name)
        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"

        keys = repo.gpg_keys
        puts "GPG Keys for #{repo_name}:\n"

        keys.each_with_index do |key, i|
          if key.keytype == "package"
            keytype = "Package signing key"
          else
            keytype = "Repository signing key"
          end

          puts "Key name: #{key.name}"
          puts "Key type: #{keytype}"
          puts "Key fingerprint: #{key.fingerprint}"
          puts "GPG key url: #{key.download_url}"
          puts
        end
      end

      desc "create user/repository /path/to/gpg-key",
           "create a package signing GPG key using the specified file"
      def create(repo_name, file_path)
        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"
        repo.create_gpg_key(file_path)
      end

      desc "destroy user/repository keyname",
           "destroy specified package signing GPG key"
      def destroy(repo_name, keyname)
        ARGV.clear
        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"

        key = repo.gpg_keys.detect do |key|
          key.name == keyname
        end

        if key
          msg = "\nAre you sure you want to delete the GPG key #{keyname}? (y/n)"
          answer = get_valid(msg) do |s|
            s == "y" || s == "n"
          end

          if answer == "y"
            print "Attempting to destroy GPG key named #{keyname}... "
            begin
              key.destroy
            rescue RestClient::ResourceNotFound =>e
              print "\nError, could not find key: #{keyname}. No GPG keys deleted.\n".color(:red)
              print "Please note that you cannot delete repository signing keys.\n"
              exit(1)
            else
              print "success!\n".color(:green)
            end
          else
            puts "Aborting...".color(:red)
          end
        else
          puts "Wasn't able to find a GPG key name: #{keyname}".color(:red)
        end
      end
    end
  end
end
