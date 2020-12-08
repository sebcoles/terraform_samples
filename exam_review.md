# Terraform Exam Review

## Understand Infrastructure as Code (IaC) concepts

### Example what IaC is

Infrastructure as code is where infrastructure is defined in code & versioned in source control. This allows for predictable and consistent deployments.

### Describe advantages of IaC patterns

- Automated deployments
- Consistent environments
- Repeatable process
- Reusable components
- Documented architecture

## Understand Terraform's purpose (vs other IaC)

### Explain multi-cloud and provider-agnostic benefits

Mulit cloud is fault tolerant. Cloud provider tools such as Azure CLI only work for their cloud. Terraform is agnositc allowing for multi cloud deployments.

### Explain the benefits of state

- Not all resources support tags, and not all cloud providers support tags.
- Explicit mapping via state is unambigious.
- State also records dependency order, so that if chunks of config are removed, it still knows how those dependency order to delete correctly. To do this declarativly is complex, state makes it simple.
- Running a plan against state is faster then against the providers.

## Understand Terraform basics

### Handle Terraform and provider installation and versioning

Providers are what enables Terraform to provision infrastructure, they enable the creation of resources. Terraform uses a plugin architecture where new open source providers can be written, upadated and consumed by terraform. Common providers are the `azurerm` provider for working with Azure and the `aws` provider.

Providers are then described in the syntax. When calling `terraform init` these providers will be downloaded. The block of the body is the configuration settings. Providers can be viewed on the Terraform Registry, along with configuration and versioning documentation.

```terraform
provider "aws" {
    access_key = "var.access_key"
    secret_key = "var.secret_key"
    region = "var.access_key"
}

```

Sometimes you may use mutliple instances of the same provider, perhaps with different credentials for example. To differentiate providers of the same type the `alias` property can be set. An alternate provider can then be specified in a resource using the alias e.g.

```terraform
provider "aws" {
    alias = "west"
    ...
}

resource "aws_instance" "ex" {
    provider = aws.west
}
```

Expressions can be used in the provider configuration, but must reference known values before a deployment, such as variables.

Previously it was also possible to use the `version` property within the provider to specify version constraints. This has been superseeded to know use the required_provider property in the terraform code block

```terraform
terraform {
  required_providers {
    mycloud = {
      source  = "mycorp/mycloud"
      version = "~> 1.0"
    }
  }
}
```

### Describe plug-in based architecture

To enable Terraform to work with many cloud offerings it used a plugin based architecture. Cloud providers can build their own terraform OSS provider which can then be published to Terraform Registry. The provider is then configured in the .tf file and downloaded when `init` is run.

### Demonstrate using multiple providers

The below configuration utilises 2 providers, the `aws` provider and a `leanix` provider.

```terraform
provider "aws" {
  region = "eu-central-1"
}

provider "leanix" {
  url       = "${var.leanix_base_url}"
  api_token = "${var.leanix_api_token}"
}
```

### Describe how Terraform finds and fetches providers

Providers are configured using a provider configuration. The provider is then retrieved when the `init` command is run and is downloaded from the Terraform Registry.

### Explain when to use and not use provisioners and when to use local-exec or remote-exec

Provisioners are a way for terraform to run post actions on an deployment, such as copying files or running terminal commands. Provisioners are not part of the state, they will always be run. Provisioners require additional configuration such as allowing Terraform to send commands to the target resources. If a provisioner fails, they deployment will still complete (no rollback) but there will be a warning.

Some providers have post deployment options supported as part of a resource configuration, these should be used when possible. If that options is not available then a provisioner such as local-exec will allow CLI commands to be run on the destination.

This is not recommended and using a proper configuration solution such as Ansible or PowershellDSC is a better approach.

```terraform
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    command = "echo The server's IP address is ${self.private_ip}"
  }
}
```

## Use the Terraform CLI (outside of core workflow)

### fmt

Running `terraform fmt` within a directory will use terraform to auto format all the .tf files within a directory to the Terraform language style conventions.

```terraform
-list=false // Don't list
-write=false // Don't overwrite
-diff // Display diff
-check // return 0 if OK
-recursive // recurse directory
```

### taint

We can mark resources in Terraform as tainted to force their recreation when running apply. The taint command marks the resource as tainted within the state file, it is not recreated until the apply is run. This can be reveresed using `untaint`

### import

Import allows none terraform provisioned infrastructure to be absorbed into a terraform configuration. Note: this does not generate configuration, this still needs to be written, it just enables Terraform to take into account already created resources.

Apply is run as `terraform import [options] ADDRESS ID`. The address is a resource address in Terraform and the ID is the ID of the resource, for example `i-abcd1234` is an example of an instance ID for an AWS instance. An example of the import workflow steps are below.

- Get IDs of existing infrastructure
- Use import to get the resources added to state
- Write the terraform configuration for those
- `plan`
- `apply`

### workspaces

Workspaces are like branches for one state file. It can be used to run the same configuration with different variables and is commonly used to deploy a DEV, QA & PRD version of the configuration. The default workspace is called `default`

To create a new workspace you would run `terraform workspace new production`which will automatically switch you to the workspace. To switch to another workspace you can call select `terraform workspace select development`.

Workspaces can be interpolated into a terraform configuration by using `${terraform.workspace}`

### state

### Debugging

To enable Terraform logging we set the `TF_LOG` environment variable to either `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`. To set an output for persistent log storage we set the environment variable `TF_LOG_PATH`.

If Terraform crashes it will write a log file to `crash.log` which produces some sort of stacktrace that can be added to a GitHub issue.

## Interact with Terraform modules

A module is a container for multiple resources that are used together as a mechanism to encapsulate and reuse configurations. Modules can refer to other modules and the same module can be called many times in a configuration. A modules resources are hidden from the calling configuration, but modules can specify `output` resources that can be used. Version constraints can also be set in the configuration.

```terraform
module "servers" {
  source = "./app-cluster"
  version = "0.0.5"
  servers = 5
}

resource "aws_elb" "example" {
  instances = module.servers.instance_ids
}
```

Modules usually inherit the providers from the calling configuration. Providers can also be set explicitly

```terraform
provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

module "example" {
  source    = "./example"
  providers = {
    aws = aws.usw2
  }
}
```

### Contrast module source options

Modules can be sourced locally by using a local directory in the `source` parameter or they can be pulled from Terraform Registry using the path. By default only verified modules (Terraform attests them) are shown in the registry search, but this filter can be turned off.

### Interact with module inputs and outputs

Input variables are used to pass values from the calling module to the child module. Output values are the returns of modules. If a module specifies output values then can then be used by the calling modules e.g.

### Describe variable scope within modules/child modules

Called modules are encapsulated, the attributes are variables cannot be access by the calling module (values need to be returned as outputs), nor can the child module access variables of the calling block (they need passed as inpout values that match attributes in the module code block).

### Discover modules from the public Terraform Module Registry

The Terraform Registry is integrated into Terraform and the syntax for referring to a module is
`<NAMESPACE>/<NAME>/<PROVIDER>`. To browse a private terraform registry a hostname can be prefixed to the module source.

### Defining module version

To constraint the version for the calling configuration the `version` property is set

```terraform
module "servers" {
  source = "./app-cluster"
  version = "0.0.5"
}
```

Registry modules support versioning which is done by the Terraform Registry.

## Navigate Terraform workflow

### Describe Terraform workflow ( Write -> Plan -> Create )

.tf files are written with the configuration of the desired infrastructure. `init` is called to install the providers. The .tf files can the be formatted with `fmt` and validated with `validate`.

With .tf completed we can create a plan using `plan` which will compare the configuration against the current Terraform state. It will also validate variables being defined. Plans can be written out using `plan -out "plan.tfplan"`.

The last stage is to `apply` the configuration, which will create the desired configuration.

### Initialize a Terraform working directory (terraform init)

`init` initalises the terraform working directory, downloads providers and creates the state.

### Validate a Terraform configuration (terraform validate)

Once initalised it is possible to call `validate` which ensures the terrafor is valid and the nessecary values of the resources are being set.

### Generate and review an execution plan for Terraform (terraform plan)

With a valid set of .tf files we can then can `plan` a deployment. This file can written `-out` for review. To view the plan we can use `terraform show`.

### Execute changes to infrastructure with Terraform (terraform apply)

We can then `apply` the plan which will provision the infrastructure.

### Destroy Terraform managed infrastructure (terraform destroy)

This can then be destory using `destroy`. By default this will require interactive confirmation which can be overridden with `-force`

## Implement and maintain state

### Describe default local backend

### Outline state locking

### Handle backend authentication methods

### Describe remote state storage mechanisms and supported standard backends

### Describe effect of Terraform refresh on state

### Describe backend block in configuration and best practices for partial configurations

### Understand secret management in state files

## Read, generate, and modify configuration

### Demonstrate use of variables and outputs

### Describe secure secret injection best practice

### Understand the use of collection and structural types

### Create and differentiate resource and data configuration

### Use resource addressing and resource parameters to connect resources together

### Use Terraform built-in functions to write configuration

### Configure resource using a dynamic block

### Describe built-in dependency management (order of execution based)

Once of the advantages of terraform and state is that dependencies are automatically managed within state. It is not nessecary to state in configuration what depends on each other, Terraform will resolve this for us. As this relationship is saved in state, even if chunks of configuration are removed, Terraform will still rewind the dependencies correctly as it destroys the elements from state.

## Understand Terraform Cloud and Enterprise capabilities

### Describe the benefits of Sentinel, registry, and workspaces

Sentinel is a policy as code tool that enables simple unit tests to be created and run against a terraform configuration. It is also possible to mock out the tests using JSON. This is to ensure secure configurations.

Registry is a private repository for modules to enable code sharing.

Cloud workspaces are a managed offering for providing an environments to run terraform. The managed workspaces contain state, variables and a secrets offering. They also provide a state and run historys and access control to workspaces.

### Differentiate OSS and Terraform Cloud workspaces

The CLI `workspace` creates another working area for state that can be used with the same configuration, for example deploying a QA or PRD version of the configuration.

Cloud workspaces are a managed offering for providing an environments to run terraform. The managed workspaces contain state, variables and a secrets offering. They also provide a state and run historys and access control to workspaces.

### Summarize features of Terraform Cloud

Terraform provide a cloud offering (Terraform Cloud) which provides an enviroment to run terraform from and handles remote state. They claim easy access to shared states, secrets solution, access control, a private registry for modules and policy controls. This is free for small teams and charges for medium teams.
