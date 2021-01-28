module PackageCloud
  module CLI 
    class MasterToken < Base
      desc "list user/repository",
           "list master tokens for specified repository"
      def list(repo_name)
        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"

        tokens = repo.master_tokens
        puts "Tokens for #{repo_name}:"
        puts ""
        tokens.each_with_index do |token, i|
          puts "  #{token.name} (#{token.value})"
          puts "  read tokens:"
          token.read_tokens.each do |read_token|
          puts "    { id: #{read_token.id}, name: #{read_token.name}, value: #{read_token.value} }"
          puts
          end
          puts "" unless i == tokens.length - 1
        end
      end

      desc "create user/repository token_name",
           "create a master token for the specified repository"
      def create(repo_name, token_name)
        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"

        print "Attempting to create token named #{token_name}... "
        resp = repo.create_master_token(token_name)
        print "success!\n".color(:green)
        print "Master token #{resp['name']} with value #{resp['value']} created.\n"
      end

      desc "destroy user/repository token_name",
           "destroy a master token for the specified repository"
      def destroy(repo_name, token_name)
        ARGV.clear # otherwise gets explodes

        if token_name == "default"
          abort("You can't delete the default master_token.".color(:red))
        end

        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_name)
        print "success!\n"

        token = repo.master_tokens.detect do |token|
          token.name == token_name
        end

        if token
          msg = "\nAre you sure you want to delete #{token_name}?"
          msg << " #{token.read_tokens.length} read tokens will no longer work afterwards (y/n)" if token.read_tokens.length > 0
          answer = get_valid(msg) do |s|
            s == "y" || s == "n"
          end
          if answer == "y"
            print "Attempting to destroy token named #{token_name}... "
            token.destroy
            print "success!\n".color(:green)
          else
            puts "Aborting...".color(:red)
          end
        else
          puts "Wasn't able to find a token named #{token_name}.".color(:red)
          exit(1)
        end
      end
    end
  end
end
