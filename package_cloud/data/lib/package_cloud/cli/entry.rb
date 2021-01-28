module PackageCloud
  module CLI
    JAVA_EXTS = ["jar", "aar", "war"]
    PY_EXTS = ["gz", "bz2", "z", "tar", "egg-info", "zip", "whl", "egg"]
    NODE_EXTS = ["tgz"]
    SUPPORTED_EXTS = JAVA_EXTS + PY_EXTS + NODE_EXTS + ["gem", "deb", "rpm", "dsc"]

    class Entry < Base
      desc "repository SUBCMD ...ARGS", "manage repositories"
      subcommand "repository", Repository

      desc "distro SUBCMD ...ARGS", "manage repositories"
      subcommand "distro", Distro

      desc "master_token SUBCMD ...ARGS", "manage master tokens"
      subcommand "master_token", MasterToken

      desc "read_token SUBCMD ...ARGS", "manage read tokens"
      subcommand "read_token", ReadToken

      desc "gpg_key SUBCMD ...ARGS", "manage GPG keys"
      subcommand "gpg_key", GpgKey

      desc "promote user/repo[/distro/version] [@scope/]package_name user/destination_repo",
           "promotes a package from user/repo [in dist/version] to user/destination_repo [also in dist/version]"
      def promote(source_repo_desc, package_name, dest_repo_desc)
        repo_name = source_repo_desc.split("/")[0..1].join("/")
        dist = expand_dist_shortcut(source_repo_desc.split("/")[2..3].join("/"))

        dest_repo_name = expand_dist_shortcut(dest_repo_desc.split("/")[0..1].join("/"))

        if dist == "" && package_name =~ /\.gem$/
          dist = "gems"
        end

        print "Looking for source repository at #{repo_name}... "
        src_repo = client.repository(source_repo_desc)
        print "success!\n"

        print "Looking for destination repository at #{dest_repo_name}... "
        repo = client.repository(dest_repo_desc)
        print "success!\n"

        if package_name.include?('@')
          scope, unscoped_package_name = package_scope(package_name)

          print "Attempting to promote scoped package #{scope}/#{unscoped_package_name} from #{repo_name}/#{dist} to #{dest_repo_name}..."
          packages = src_repo.promote(dist, unscoped_package_name, dest_repo_name, scope)
        else
          print "Attempting to promote #{repo_name}/#{dist}/#{package_name} to #{dest_repo_name}..."
          packages = src_repo.promote(dist, package_name, dest_repo_name)
        end
        puts "done!".color(:green)

        if dist == "node/1"
          puts "WARNING: This Node.js package will NOT be downloadable by clients until a dist tag is created. Read more: https://packagecloud.io/docs/#node_promote".color(:yellow)
        end
      end

      desc "yank user/repo[/distro/version] [@scope/]package_name",
           "yank package from user/repo [in dist/version]"
      def yank(repo_desc, package_name)
        ARGV.clear # otherwise gets explodes

        # strip os/dist
        repo_name = repo_desc.split("/")[0..1].join("/")
        dist = expand_dist_shortcut(repo_desc.split("/")[2..3].join("/"))

        if dist == "" && package_name =~ /\.gem$/
          dist = "gems"
        end

        print "Looking for repository at #{repo_name}... "
        repo = client.repository(repo_desc)
        print "success!\n"

        if package_name.include?('@')
          scope, unscoped_package_name = package_scope(package_name)
          print "Attempting to yank scoped package at #{repo_name}/#{dist} #{package_name}..."
          repo.yank(dist, unscoped_package_name, scope)
        else
          print "Attempting to yank package at #{repo_name}/#{dist}/#{package_name}..."
          repo.yank(dist, package_name)
        end
        puts "done!".color(:green)

        if dist == "node/1"
          puts "WARNING: Deleting Node.js packages can have unexpected side effects with dist tags. Read more: https://packagecloud.io/docs/#node_delete".color(:yellow)
        end
      end

      desc "push user/repo[/distro/version] /path/to/packages",
           "Push package(s) to repository (in distro/version, if required). Optional settings shown above."

      option "skip-file-ext-validation", :type => :boolean,
                                         :desc => "Skip checking validation of the file extension. Package upload will be attempted even if the extension is unrecognized."

      option "yes", :type => :boolean,
                    :desc => "Automatically answer 'yes' prompted during package push. Useful for automating uploads."

      option "skip-errors", :type => :boolean,
                            :desc => "Skip errors encountered during a package push and continue pushing the next package."

      option "coordinates", :type => :string,
                            :desc => "Specify the exact maven coordinates to use for a JAR. Useful for JARs without coordinates, 'fat JARs', and WARs."

      def push(repo, package_file, *package_files)
        total_time = Benchmark.measure do
          ARGV.clear # otherwise gets explodes
          package_files << package_file

          exts = package_files.map { |f| f.split(".").last }.uniq

          if package_files.length > 1 && exts.length > 1
            abort("You can't push multiple packages of different types at the same time.\nFor example, use *.deb to push all your debs at once.".color(:red))
          end

          invalid_packages = package_files.select do |f|
            !SUPPORTED_EXTS.include?(f.split(".").last.downcase)
          end

          if JAVA_EXTS.include?(exts.first.downcase) && options.has_key?("coordinates")
            puts "Using coordinates #{options["coordinates"].color(:yellow)}"
          end

          if !options.has_key?("skip-file-ext-validation") && invalid_packages.any?
            message = "I don't know how to push these packages:\n\n".color(:red)
            invalid_packages.each do |p|
              message << "  #{p}\n"
            end
            message << "\npackage_cloud only supports node.js, deb, gem, java, python, or rpm packages".color(:red)
            abort(message)
          end

          if !options.has_key?("yes") && exts.first == "gem" && package_files.length > 1
            answer = get_valid("Are you sure you want to push #{package_files.length} packages? (y/n)") do |s|
              s == "y" || s == "n"
            end

            if answer != "y"
              abort("Aborting...".color(:red))
            end
          end

          validator = Validator.new(client)
          if PY_EXTS.include?(exts.first.downcase)
            dist_id   = validator.distribution_id(repo, package_files, 'py')
          elsif NODE_EXTS.include?(exts.first.downcase)
            dist_id   = validator.distribution_id(repo, package_files, 'node')
          elsif JAVA_EXTS.include?(exts.first.downcase)
            abort_if_snapshot!(package_files)
            dist_id   = validator.distribution_id(repo, package_files, 'jar')
          else
            dist_id   = validator.distribution_id(repo, package_files, exts.first)
          end

          # strip os/dist
          split_repo = repo.split("/")[0..1].join("/")

          print "Looking for repository at #{split_repo}... "
          client_repo = nil
          measurement = Benchmark.measure do
            client_repo = client.repository(split_repo)
          end
          print "success!\n"
          $logger.debug("repository lookup request timing: #{measurement}")

          package_files.each do |f|
            files = nil
            ext = f.split(".").last

            if ext == "dsc"
              print "Checking source package #{f}... "
              files = parse_and_verify_dsc(client_repo, f, dist_id)
            end

            print "Pushing #{f}... "
            measurement = Benchmark.measure do
              if options.has_key?("skip-errors")
                create_package_skip_errors(client_repo, f, dist_id, files, ext, options["coordinates"])
              else
                create_package(client_repo, f, dist_id, files, ext, options["coordinates"])
              end
            end
            $logger.debug("create package request timing: #{measurement}")
          end
        end
        $logger.debug("push command total timing: #{total_time}")
      end

      desc "version",
           "print version information"
      def version
        puts "package_cloud CLI #{VERSION}\nSee https://packagecloud.io/docs#cli for more details."
      end

      private
        def expand_dist_shortcut(dist)
          case dist
          when 'java'
            'java/maven2'
          when 'python'
            'python/1'
          when 'node'
            'node/1'
          else
            dist
          end
        end

        def package_scope(package_name)
          name_parts = package_name.split('/')
          if name_parts.size != 2 || !package_name.include?('@')
            abort("Could not determine scope for '#{package_name}', it should look like: @my-scope/package-1.0.tgz".color(:red))
          end
          scope = name_parts[0]
          unscoped_package_name = name_parts[1]
          [scope, unscoped_package_name]
        end

        def abort_if_snapshot!(files)
          if files.any? { |file| file.include?("-SNAPSHOT")  }
            abort("SNAPSHOT uploads are not supported by the CLI, please use Maven instead: https://packagecloud.io/docs#wagon-instructions")
          end
        end

        def create_package_skip_errors(client_repo, f, dist_id, files, ext, coordinates=nil)
          begin
            client_repo.create_package(f, dist_id, files, ext, coordinates=nil)
          rescue RestClient::UnprocessableEntity => e
            print "error (skipping):\n".color(:yellow)
            json = JSON.parse(e.response)
            json.each do |k,v|
              puts "\n\t#{k}: #{v.join(", ")}\n"
            end
            puts ""
          end
        end

        def create_package(client_repo, f, dist_id, files, ext, coordinates=nil)
          begin
            client_repo.create_package(f, dist_id, files, ext, coordinates)
          rescue RestClient::UnprocessableEntity => e
            print "error:\n".color(:red)
            json = JSON.parse(e.response)
            json.each do |k,v|
              if v.is_a? String
                puts "\n\t#{k}: #{v}\n"
              elsif v.is_a? Array
                puts "\n\t#{k}: #{v.join(", ")}\n"
              end
            end
            puts ""
            exit(1)
          end
        end

        def parse_and_verify_dsc(repo, f, dist_id)
          files = repo.parse_dsc(f, dist_id)
          dirname = File.dirname(f)
          find_and_verify(dirname, files)
        end

        def find_and_verify(dir, files)
          file_paths = []
          files.each do |f|
            filepath = File.join(dir, f["filename"])
            if !File.exists?(filepath)
              print "Unable to find file name: #{f["filename"]} for source package: #{filepath}\n".color(:red)
              abort("Aborting...".color(:red))
            end

            disk_size = File.stat(filepath).size
            if disk_size != f["size"]
              print "File #{f["filename"]} has size: #{disk_size}, expected: #{f["size"]}\n".color(:red)
              abort("Aborting...".color(:red))
            end

            print "Found DSC package file #{f["filename"]} for upload\n"

            file_paths << filepath
          end
          file_paths
        end

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
    end
  end
end
