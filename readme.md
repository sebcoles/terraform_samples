# Terraform notes

## IaC

Infrastructure as code is where infrastructure is defined in code & versioned in source control. This allows for predictable and consistent deployments. Terraform is `idopotent` which is a pretentious word for stateful. Terraform will compare configuration changes to a state kept in a JSON file to work out what actions are needed to add, modified or remove resources.

## Benefits

- Automated deployments
- Consistent environments
- Repeatable process
- Reusable components
- Documented architecture

## Components

### Terraform Executable

Terraform is a go application that needs installed on the machine running the terraform commands.

### .tf Files

Terraform uses .tf files and will consume all the .tf files in the local directory. Simple terraform configurations may only contain the `main.tf` file, but once the configuration becomes more complicated it is common to break this file into sub section such as

- `variables.tf`
- `modules.tf`
- `providers.tf`

### Providers

Providers are what enables Terraform to provision infrastructure, they enable the creation of resources. Terraform uses a plugin architecture where new open source providers can be written, upadated and consumed by terraform. Common providers are the `azurerm` provider for working with Azure and the `aws` provider.

## Syntax

### Variables

Variables in Terraform are created using the `variable` keyword:

```
// Simple variable
variable "aws_secret_key" {}

// Variable with properties
variable "aws_region" {
    Default = "us-east"
}
```

### Providers

Providers are then described in the syntax. When calling `terraform init` these providers will be downloaded. The block of the body is the configuration settings. Providers can be viewed on the Terraform Registry, along with configuration and versioning documentation.

```
provider "aws" {
    access_key = "var.access_key"
    secret_key = "var.secret_key"
    region = "var.access_key"
}
```
Sometimes you may use mutliple instances of the same provider, perhaps with different credentials for example. To differentiate providers of the same type the `alias` property can be set. An alternate provider can then be specified in a resource using the alias e.g.

```
provider "aws" {
    alias = "west"
    ...
}

resource "aws_instance" "ex" {
    provider = aws.west
}
```


### Data

We may need to query the target infrastrucutre for information needed in the deployment. The `data` syntax is used to describe a query, and the results can be used later in the workflow. For example the below syntax creates a data type called aws_ami.aix which will query AWS for the latest linux AMI.

```

data "aws_ami" "aix" {
    most_recent = true
    owners = "linux"
    filters = {}
    }
}
```

### Resource

Fundamental purpose of terraform is to create resources. The below syntax will provision a VM in AWS
```
resource "aws_instance" "ex" {
    ami = "data.aws_ami.alx.id"
    instance_type = "t2.micro"
}
```

### Output

After running our configuration we may also want to output data from the provisioning, such as the IP address or public DNS of the provisioned resources.
```

output "aws_public_ip" {
    value = "aws_instance.ex.public_dns"
}

```


## State
Terraform needs state to be idopotent. State holds information on what resources have been provisionised through terraform. It may also hold dependency information so that it knows how to delete reosurces.

By default Terraform stores it's state in the same directory where Terraform is run in a terraform.tfstate file. This has challenges when working in teams, so it is best practise to share state using a remote data source such as storing the state in Azure Blob storage or another shared directory.

## Terraform Settings
Terraform can be used with additional configuration using the terraform block, for example specifying a version of terraform or the loction of a remote state.

## Provisioners 
Provisioners are a way for terraform to run post actions on an deployment, such as copying files or running terminal commands.
Provisioners are not part of the state, they will always be run. Provisioners require additional configuration such as allowing Terraform to send commands to the target resources. If a provisioner fails, they deployment will still complete (no rollback) but there will be a warning.

## Subcommands

### init

Running `terraform init` will start to build a terraform workspace. It will read the current working directory .tf files and download the plugins and providers needed. It will also create the state for the configuration.

If init is run with a different backend in the configuration, terraform will update the directory to use the new state and run an interactive migration process. This can be forced to accept with the `-force-copy` command.

init can also be run in an empty directory if provided with the `from-module=location` command which will take a copy of the target files into the current working directory, which is good for copying templates.

### validate

Validate just checks the correctness of the configuration syntax. By default this requires a backend to be configured but can be overridden with the `backend=false` command.

### fmt

Running `terraform fmt` within a directory will use terraform to auto format all the .tf files within a directory to the Terraform language style conventions.
```
-list=false // Don't list
-write=false // Don't overwrite
-diff // Display diff
-check // return 0 if OK
-recursive // recurse directory
```

### taint

We can mark resources in Terraform as tainted to force their recreation when running apply. The taint command marks the resource as tainted within the state file, it is not recreated until the apply is run.

### Workspaces

Workspaces are like branches for one state file. It can be used to run the same configuration with different variables and is commonly used to deploy a DEV, QA & PRD version of the configuration. The default workspace is called `default`

To create a new workspace you would run `terraform workspace new production`which will automatically switch you to the workspace. To switch to another workspace you can call select `terraform workspace select development`.

Workspaces can be interpolated into a terraform configuration by using `${terraform.workspace}`

### Import

Import allows none terraform provisioned infrastructure to be absorbed into a terraform configuration. Note: this does not generate configuration, this still needs to be written, it just enables Terraform to take into account already created resources.

Apply is run as `terraform import [options] ADDRESS ID`. The address is a resource address in Terraform and the ID is the ID of the resource, for example `i-abcd1234` is an example of an instance ID for an AWS instance. An example of the import workflow steps are below.

- Get IDs of existing infrastructure
- Use import to get the resources added to state
- Write the terraform configuration for those
- `plan`
- `apply`


## Logging

To enable Terraform logging we set the `TF_LOG` environment variable to either `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`. To set an output for persistent log storage we set the environment variable `TF_LOG_PATH`.

If Terraform crashes it will write a log file to `crash.log` which produces some sort of stacktrace that can be added to a GitHub issue.

## Terraform Cloud & Enterprise

Terraform provide a cloud offering (Terraform Cloud) which provides an enviroment to run terraform from and handles remote state. They claim easy access to shared states, secrets solution, access control, a private registry for modules and policy controls. This is free for small teams and charges for medium teams. Terraform Enterprise is the same but on-prem with SSO.

## Sentinel

Sentinel is a policy as code tool that enables simple unit tests to be created and run against a terraform configuration. It is also possible to mock out the tests using JSON.

