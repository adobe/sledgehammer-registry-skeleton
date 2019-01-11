# Tool Development

The following information should help to build or update a tool. This is not
required to know for running tools!  All tools are located in the `tools`
directory of this repository and the name of the sub-directory determines the
name of the tool, i.e. the start script the installer will create.

## TL;DR

Provide a `Dockerfile`, `VERSION` and a `README.md`. Hint for the Dockerfile, always include the Version, i.e. `ARG VERSION`. <br>
If your tool does not ouput the Version number in a plain text, also provide a `test_version.sh` extracting only the version of the tool as a string. 
Use the make file to locally verify your changes:
`make <newtool>.verify`

## Structure

Every tool follows a certain structure, that determines how the container is
created in the [build process](#build-process).

```
├── assets
│   └── newtool-example-script.sh
├── Dockerfile
├── README.md
├── VERSION
├── post-build.sh
├── pre-build.sh
├── check-update.sh
└── test-version.sh
```

The `Dockerfile`, `VERSION` and `README.md` are required files. Everything else
is optional and might only be required to influence certain aspects of the
build process.

### VERSION

This file contains the version of the tool container. This is what is used to
tag images during release in the docker image repository. The version can
consist of two parts: the version of the tool and an optional container
version. Both are separated by a dash `-`. For example in `1.2.3-4` the tool
version would be `1.2.3` and `4` the container version.

The container version should always be added! The reason is that the whole version is considered a semantic version.
That means that a version `1.2.3` will always have a higher priority than `1.2.3-5` which is considered a prerelease version.
If you are sure that your container will not need any update, then feel free to omit the container version.

The tool version part will be available during the build of a container image
as `VERSION` build argument. This is what should determine the version of the
tool installed in the container! More on that in the description of the
`Dockerfile`.

If the tool version itself doesn't change, but the packaging of the tool, then
the container part of the version must be changed.

During the release of new tool container images the build system will make sure
no existing images are overwritten. Therefore every change to a tool requires a
change of the version, either the real version or the container version.


### Dockerfile

This is a regular
[Dockerfile](https://docs.docker.com/engine/reference/builder). The following
shows an example taken from the git tool:

```Dockerfile
FROM alpine
LABEL maintainer="plaschke@adobe.com"

ARG VERSION

RUN apk add ca-certificates git~=${VERSION} --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main

ENTRYPOINT ["git"]
```

The things note-worthy are the usage of the `VERSION` argument, that will
provide the tool version part as specified in the version file. It is made
available in the build container as [build
argument](https://docs.docker.com/engine/reference/builder/#arg).

An `ENTRYPOINT` should be defined. Additional helpers from the [helpers directory](https://git.corp.adobe.com/acp-cs-tooling/sledgehammer/tree/documentation/helpers) are also copied there. 
They are available to check for availability of certain credentials.

### README.md

This is the main documentation for the tool. It should provide all details
necessary for the tool, like original tool documentation and what additional
features might be available.

### pre-build.sh

The `pre-build.sh` script will be sourced into `make.sh` at build time, before
the actual docker build run starts. Use this file, to run commands you need in
preparation of the actual build.

If binaries are required during the build, those should be download at this
point (instead of committing them to the repository).


### post-build.sh

The `post-build.sh` script will be sourced into `make.sh` at build time, after
the actual docker build run has finished (no matter if successful or not). Use
this to run clean-up or other post-build steps.

This can be used to clean up downloads that were done in the `pre-build.sh`
script.


### assets

By convention this folder is used to store all assets required for the build.

### test-version.sh

After a successful build, the container is tested by invoking the included
tool's '--version' parameter.  By default, it expects to get the tool version
string as included in the `VERSION` file. This default behavior can be
overwritten, for example if the version parameter is different from `--version`
or the version returned differs from the expectation.

The script will receive the name of the docker container that has been created as a first argument.
So the script can start the docker container and gets the correct version.

The git tool for example uses:

```bash
#!/usr/bin/env bash

docker run --rm -it "${1}" --version | sed -e 's/git version //'
```

This will make sure that the environment is properly set (it wouldn't be during
container image build time) and the version output is filter to retrieve the
required output.

### check-update.sh

The registry will check daily if there are new version available for all tools.
If so it will create a new pull request which updates the version file of the given tool.

For that to work the make script will check for a `check-update.sh` file in the tools folder.
If it is avilable then the tool supports auto update and the script will be executed.

The script needs to return the current newest available version that can be used without the container version.
For an example take a look at the update file for the `git` tool.


## Build Infrastructure

During development the `<tool_name>.verify` target of the `Makefile` found in the
repositories root might be useful. It will build and verify the given tool. The
container will be available locally afterwards.

The `prb` target could be used, too. It will build only tools touched locally
or changed on the current branch. The `ci` target also uploads the newly built
and tagged container images to the docker image repository. This is disregarded
from doing locally! Only the build infrastructure should upload images!


## Containers At Runtime

When the container is run, Sledgehammer will prepare an environment for the
tool, that has certain boundaries:

* Existing environment variables are made available in the container with the
  exception of the following ones: 'PATH', 'USER',  'TMP', 'PWD',
  'SHELL' and all variables starting with an underscore '_'.
* All registered mounts will be mounted into the container and the working
  directory be set to equal the current directory. That implies that
  sledgehammer tools __only work in the user's defined mount directory__!
* Inside the container the user will have the same user and group id, as on the
  host. This is required to match file permissions for existing and created
  files.
* The container will have a tty available, if one is available, i.e. docker's
  `--tty` option will be set if applicable.

The arguments the start script of the container receives are handed down to the
`ENTRYPOINT` provided.