# packagecloud CLI

Greetings! Welcome to the [packagecloud](https://packagecloud.io) command line
client, `package_cloud`.

## Requirements

Only Ruby 2.x and greater is supported, please use version 0.2.45 for Ruby 1.9 support.

## Overview

The `package_cloud` command line client allows you to easily:

* Create Node.js, Debian, RPM, RubyGem, Python, and Maven package repositories
 on [packagecloud](https://packagecloud.io).
* Upload Node.js, Debian, RPM, RubyGem, Python, and Java JAR/WAR/AAR packages
 to your repositories.
* [Delete packages](https://packagecloud.io/docs#yank_pkg).
* [Promote packages](https://packagecloud.io/docs#promote_pkg) between
 repositories.
* Upload a package signing GPG key.
* Create and delete [master and read
  tokens](https://packagecloud.io/docs#token_auth) to control repository
  access.

This tool is intended to be used on the command line either manually or in an
automated environment (like a build or CI process). See more examples on how
to use the command-line interface by visiting the
[CLI page](https://packagecloud.io/l/cli).

## Installation

Simply run:

    gem install package_cloud

to install the command line client.

You can now run `package_cloud` from the command line to see the help message
displayed.

## Usage

### Getting help

You can run `package_cloud help` to get general help information about the
supported commands.

You can also get help information for specific commands by running
`package_cloud help [command]`. For example, to get help on pushing a package
you can run: `package_cloud help push`.

Additional documentation is also available on our [documentation
page](https://packagecloud.io/docs).

You can interact with our system programmatically as well by using our
[API](https://packagecloud.io/docs/api).

### Creating a repository

You can create a package repository named 'example' on
 [packagecloud](https://packagecloud.io) by running:

```
package_cloud repository create example
```

### Environment variables

There are two environment variables that you can use with package_cloud CLI
that will override the settings found in `~/.packagecloud`:

1. `PACKAGECLOUD_TOKEN`: This environment variable can be set to your API
   token (available [here](https://packagecloud.io/api_token)). If set, the
   CLI *will not* read the `~/.packagecloud` configuration file to get the API
   token.

2. If and only if the `PACKAGECLOUD_TOKEN` variable is set, you may also set
   `PACKAGECLOUD_URL`. This environment should only be used by
   packagecloud:enterprise customers. It allows you to set the URL of the
   packagecloud installation. Customers using our hosted, cloud based product
   should not set this variable; it is defaulted to `http://packagecloud.io`
   automatically.

### Pushing a package

You can upload Debian, RPM, RubyGem, Python, or Java packages to any
repository you've created by using the `push` command.

Most package types require specifying a `distribution/version` pair when
uploading. See the examples that follow for more information.

Please note that packages will be available for download via the packagecloud
 web UI
immediately after they are uploaded, but they will not necessarily be
available for installation via a package manager immediately. This is because
our system regenerates the repository metadata needed by package managers as a
background job on our system. Jobs are added to a queue and processed.
Processing time depends on the number of packages in your repository and the
number of reindex jobs in front of yours.

The following examples will show an example user name of `example-user` and a
 repository
name of `example-repository`.

After the examples below, there will be an additional section documenting
important optional parameters you can specify when pushing packages.

#### Uploading a Debian package

You can upload a Debian package found at the path `/tmp/example.deb` for
 Ubuntu Xenial by running:

```
package_cloud push example-user/example-repository/ubuntu/xenial /tmp/example.deb
```

This command will upload `/tmp/example.deb` to the `example-repository`
repository owned by `example-user` as an Ubuntu Xenial package.

We also support Debian source packages (DSCs). You can upload a
`/tmp/example.dsc` for Ubuntu Xenial by running:

```
package_cloud push example-user/example-repository/ubuntu/xenial /tmp/example.dsc
```

Note that all files associated with the DSC (like source tarballs, patches,
etc) must reside in the same directory as the DSC itself.

You can specify other Ubuntu or Debian versions. Consult the [full list of
combinations](https://packagecloud.io/docs#os_distro_version) to find the one
you need.

#### Uploading an RPM package

You can upload an RPM package found at the path `/tmp/example.rpm` for CentOS
6 by running:

```
package_cloud push example-user/example-repository/el/6 /tmp/example.rpm
```

This command will upload `/tmp/example.rpm` to the `example-repository`
repository owned by `example-user` as a CentOS 6 package.

You can specify other CentOS, Fedora, Oracle, Scientific Linux, or SUSE versions.
Consult the
[full list of combinations](https://packagecloud.io/docs#os_distro_version)
to find the one you need.

#### Uploading a RubyGem package

You can upload a RubyGem package found at the path `/tmp/example.gem` by
running:

```
package_cloud push example-user/example-repository /tmp/example.gem
```

This command will upload `/tmp/example.gem` to the `example-repository`
repository owned by `example-user` as a RubyGem package.

Note that unlike all other package types, RubyGems do not require any
additional specification on upload.

#### Uploading a Python package

You can upload a Python package found at the path `/tmp/example.whl` by
running:

```
package_cloud push example-user/example-repository/python /tmp/example.whl
```

This command will upload `/tmp/example.whl` to the `example-repository`
repository owned by `example-user` as a Python package.

We also support Python eggs and source distributions. Note that recent
versions of pip no longer support installing Python eggs and will fail to find
eggs in PyPI repositories.

If you'd like to upload a Python egg despite this, you can do so by running:

```
package_cloud push example-user/example-repository/python /tmp/example.egg
```

#### Uploading a Java JAR, WAR, or AAR package

You can upload a Java JAR package found at the path `/tmp/example.jar` by
running:

```
package_cloud push example-user/example-repository/java/maven2 /tmp/example.jar
```

WAR files can be uploaded the same way.

It is important to note that in some cases (for example: 'fat JARs', or JARs
without `pom.xml` files, etc) our system will not be able to automatically
 detect
the [Maven coordinates](https://maven.apache.org/pom.html#Maven_Coordinates).
In these cases you will receive an error, and you should specify the
coordinates manually on the command line:

```
package_cloud push example-user/example-repository/java/maven2 /tmp/example.jar --coordinates=com.mygroup:packagename:1.0.2
```

#### Uploading a Node.js package

To upload a Node.js package located at `/tmp/test-1.0.0.tgz` to a packagecloud
 NPM registry called `example-user/example-repository`:

```
package_cloud push example-user/example-repository/node /tmp/example-1.0.tgz
```

#### Additional options

There are a few additional options you can use to fine tune package upload for
more advanced use cases:

* `--skip-file-ext-validation` - The CLI will attempt to verify the package's
  file extension. In some cases, this may be unwanted (for example, when
  uploading a randomly generated file name). You can ask the CLI to avoid
  checking the file extension by specifying this flag.
* `--yes` - When uploading multiple packages the CLI will prompt the user to
  verify their request by typing 'y'. You can skip the prompt by passing this
  flag.
* `--skip-errors` - Sometimes a mass upload of a directory full of packages
  may fail or be canceled by the user. If you want to re-upload all files
  without having to manually remove files you have already uploaded, you can
  use this flag to skip the duplicate file errors and force the CLI to
  continue uploading packages.
* `--coordinates` - This flag is used for Java JARs or WARs which do not have
  an internal `pom.xml` specifying the Maven coordinates. You can specify your
  own Maven coordinates for this file using this flag:
   `--coordinates=com.mygroup:packagename:1.0.2`.
* `--config` - This flag is used to specify a custom configuration file path
  for the CLI. This file specifies the website URL and your API token. This is
  default to `~/.packagecloud`.
* `--url` - This flag is sued to specify a custom URL as the packagecloud
  server. This option is used by packagecloud:enterprise customers to point to
  their installation.
* `--verbose` - This flag is used to generate additional debug information for
  push operations and is very useful if submitting a bug report to
  packagecloud :)

### Deleting a package

You can remove a package by using the `yank` command. You will need to specify
the full filename of the package and the distribution / version pair (except
for RubyGems).

Removing a package will
make the package immediately inaccessable from the packagecloud web UI, but it
may take a few moments for the package to be removed from the repository
metadata because removals trigger a reindex of the repository.

#### Deleting a Debian package

You can delete a Debian package named `example_1.0.1-1_amd64.deb` that was
uploaded for Ubuntu Xenial from the repository `example-repository` owned by
the user `example-user` by running the following command:

```
package_cloud yank example-user/example-repository/ubuntu/xenial example_1.0.1-1_amd64.deb
```

This will delete the package and trigger a reindex of the repository's
metadata.

#### Deleting an RPM package

You can delete an RPM package named `example-1.0-1.x86_64.rpm` that was
uploaded for CentOS 6 from the repository `example-repository` owned by
the user `example-user` by running the following command:

```
package_cloud yank example-user/example-repository/el/6 example-1.0-1.x86_64.rpm
```

This will delete the package and trigger a reindex of the repository's
metadata.

#### Deleting a RubyGem package

You can delete a RubyGem package named `example-1.0.gem` from the
repository `example-repository` owned by the user `example-user`
by running the following command:

```
package_cloud yank example-user/example-repository example-1.0.gem
```

This will delete the package and trigger a reindex of the repository's
metadata.

#### Deleting a Python package

You can delete a Python package named `example-1.0.1.whl` from the repository
`example-repository` owned by the user `example-user` by running the following
command:

```
package_cloud yank example-user/example-repository/python example-1.0.1.whl
```

This will delete the package and trigger a reindex of the repository's metadata.
Python eggs and sdists can be deleted in a similar manner.

#### Deleting a Java package

You can delete a Java package named `example-1.0.3.jar` with the group
 `com.groupid` from the repository
`example-repository` owned by the user `example-user` by running the following
command:

```
package_cloud yank example-user/example-repository/java com.groupid/example-1.0.3.jar
```

This will delete the package and trigger a reindex of the repository's
metadata. WARs can be deleted in a similar manner.

#### Deleting a Node.js package

You can delete a Node.js package named `example-1.0.tgz` from the NPM registry
`example-repository` owned by the user `example-user` by running the following
command:

```
package_cloud yank example-user/example-repository/node example-1.0.tgz
```

If the package has a scope, you can delete it by passing the scope like so:

```
package_cloud yank example-user/example-repository/node @scoped-user/example-1.0.tgz
```

This will delete the package and trigger a reindex of the registry's
metadata.

Note that deleting Node.js packages can have unexpected side effects when
mixed with
 [NPM distribution tags](https://docs.npmjs.com/getting-started/using-tags). Read
more about how [promoting on packagecloud can affect dist tags
here.](https://packagecloud.io/docs/#node_promote)

### GPG Keys

Some package managers use [GPG keys](https://packagecloud.io/docs#gpg)
to verify that a package was created by the author and not an impersonator.

If you sign your packages with a GPG key before you upload them to
packagecloud, your package will still be signed when the user downloads it.

In these cases, especially with YUM repositories, it is useful to upload the
public GPG key that can verify the package you signed. When a user installs
your repository, the associated GPG key will be installed on their system and
used for verifying the package.

The follow sections will illustrate how to upload, list, and delete GPG keys.

#### Uploading a package signing GPG key

To upload a GPG key located on
your system at `/tmp/gpg.key` for the repository `example-repository` owned by
the user `example-user`, you can run the following command:

```
package_cloud gpg_key create example-user/example-repository /tmp/gpg.key
```

Note that if you attempt to upload a private key to packagecloud, we will
extract only the public key component. The private key will then be discarded.
We do not store or persist private keys at all.

#### Listing GPG keys associated with a repository

You can list the GPG keys associated with the repository `example-repository`
owned by user `example-user` by running the following command:

```
package_cloud gpg_key list example-user/example-repository
```

The key name specified in the output of this command is the key name you should
specify when deleting the key.

#### Deleting GPG keys associated with a repository

You can delete the GPG key named
`example-user-example-repository-56D06.pub.gpg` associated with the repository
named `example-repository` and owned by the user `example-user` by running the
following command:

```
package_cloud gpg_key destroy example-user/example-repository example-user-example-repository-56D06.pub.gpg
```

You can get the key name for a key you'd like to delete by using the GPG key
list command above.

### Promoting packages between repositories

Package promotion is a feature which can be used to easily move packages
between repositories. This is useful for moving a package from a private
staging repository to a public production ready repository during a software
 release workflow.

To move a package named `example_1.0-1_amd64.deb` from the user
`example-user`'s repository named `repo1` over to the same users repository
named `repo2`, you would issue the following command:

```
package_cloud promote example-user/repo1/ubuntu/xenial example_1.0-1_amd64.deb example-user/repo2
```

If the package has a scope (Node.js packages), you can promote it by including
 the scope like so:

```
package_cloud promote example-user/repo1/node @scoped-user/example-1.0.tgz example-user/repo2
```

If the package has a group (Java packages), you can promote it by
 including the group like so:

```
package_cloud promote example-user/repo1/java com.groupid/jake-2.3.jar example-user/repo2
```

After the package is moved, a reindex will be triggered for both `repo1`
 and `repo2`.

Note that promoting Node.js packages can have unexpected side effects when
mixed with
[NPM distribution tags](https://docs.npmjs.com/getting-started/using-tags).
 Read more about how [promoting on packagecloud can affect dist tags
here](https://packagecloud.io/docs/#node_promote).

### Creating, deleting, and listing master and read tokens

The [token authentication](https://packagecloud.io/docs/#token_auth) system
used for repositories allows fine grained access control of repositories.

Master tokens can be used just for creating additional read tokens. Master
tokens themselves do not provide read access to a repository. Deleting
a master token automatically deletes all associated read tokens.

A typical use case for our token system would be a SaaS service distributing
a monitoring agent who wants to control download access to their repository.

A master token can be created per customer that signs up and read tokens
associated with the generated master token can be assigned per system. Then,
the read tokens can be deleted one at a time (to disable access on a
per-machine basis) or completely by deleting the associated master token.

#### Creating master tokens

Following from the example explained in the previous section,
you can create a master token name "Example-Token" for the repository
`example-repository` owned by the user `example-user` by running the following
command:

```
package_cloud master_token create example-user/example-repository Example-Token
```

#### Listing master tokens

You can list all master tokens associated with the repository
`example-repository` owned by the user `example-user` by running the following
command:

```
package_cloud master_token list example-user/example-repository
```

#### Deleting master tokens

You can delete the token named `Example-Token` associated with the
repository `example-repository` owned by the user `example-user` by running
the following command:

```
package_cloud master_token destroy example-user/example-repository Example-Token
```

This will also automatically delete all read tokens associated with this
master token, thereby revoking read access to the repository with those
tokens.

## Still need help?

Feel free to reach out to
[support@packagecloud.io](mailto:support@packagecloud.io) with questions.
