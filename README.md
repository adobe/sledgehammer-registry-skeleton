Registry skeleton for containerized tools
======

### Introduction

This is a skeleton registry that can be cloned and used for internal or custom tools.
The only thing that needs to be changed is in the variables in the `make.sh` file.

There are two tool examples in the tool folder to demonstrate the different possibilities for tools.

For reference you can always look at the default registry at https://github.com/adobe/sledgehammer-registry

#### Kits 

To add a tool kit to the index.json you can use the following snippet (taken from the default registry)

    {
        "name": "slh-dev",
        "description": "Provides tools to build and test Sledgehammer and the default registry",
        "tools": [
            {
                "name": "shellcheck"
            },
            {
                "name": "alpine-version"
            },
            {
                "name": "modify-repository"
            },
            {
                "name": "jq"
            }
        ]
    },

### Contributing

Contributions are welcomed! Read the [Contributing Guide](CONTRIBUTING.md) for more information.

### Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.