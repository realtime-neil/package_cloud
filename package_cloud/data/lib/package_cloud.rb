require "package_cloud/version"
require "cgi"
require 'rainbow/ext/string'

module PackageCloud
  autoload :Auth, "package_cloud/auth"
  autoload :CLI, "package_cloud/cli"
  autoload :Client, "package_cloud/client"
  autoload :ConfigFile, "package_cloud/config_file"
  autoload :MasterToken, "package_cloud/master_token"
  autoload :Object, "package_cloud/object"
  autoload :ReadToken, "package_cloud/read_token"
  autoload :Repository, "package_cloud/repository"
  autoload :Validator, "package_cloud/validator"
  autoload :Util, "package_cloud/util"
  autoload :GpgKey, "package_cloud/gpg_key"
end
