- [OCI](#oci)
  - [Prerequisites:](#prerequisites)
  - [Managing Different Environments](#managing-different-environments)
    - [Environemnt Configuration](#environemnt-configuration)
    - [Considerations](#considerations)
    - [Advantage of using the above approach:](#advantage-of-using-the-above-approach)
  - [Getting Started](#getting-started)
  - [Modules](#modules)
- [Releases](#releases)
  - [oci provider version](#oci-provider-version)
  - [Using the module in your project from github.com:](#using-the-module-in-your-project-from-githubcom)
- [Contributors](#contributors)

# OCI
Ready Module for common Oracle Cloud Infrastracture services that make it easy to setup and create your infrastracture as code. The repo contains some custom modules that are built on the top of official oci provider. This repository provides ready and handy modules to use to spin up production ready infra in Oracle Cloud.

Note that, you will not be able to manage your infra 100% as code, however, what we aimed at is to be **80%-90%**, as some manual setup will still be required.

## Prerequisites:
1. You need an account with oracle, and you must have setup your public key in your account. Consult oracle docs for how to setup your account to use oci api [here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm).
2. `terraform` binary downloadable from [here](https://www.terraform.io/downloads.html).

## Managing Different Environments
There are multiple ways on how to manage environments in Terraform. What is suggested here is to let terraform manages multiple workspaces, each state is scoped to an environment. Environments states are stored differently in remote state file as specified in the `configurations.tf` file. Environments can be found under `environments` directory. Here is a suggestion on how to organise your different environments.
```
environments/
  production/
      variables.tf
      provider.tf
      output.tf
      data.tf
      configurations.tf.  <--------- using production workspace in Terraform
      main.tf   <------ specific environment infra goes here
      ...
      ...
  uat/
      variables.tf
      provider.tf
      output.tf
      data.tf
      configurations.tf.  <--------- using uat workspace in Terraform backend
      main.tf   <------ specific environment infra goes here
      ...
      ...
```

*NOTE* Since `compartments`, `users`, `groups`, and `policies` are not scoped to specific environments, and they apply at the account/tenant level, it is advisable to have a concept of gloabl environment, where states in this environment will affect the whole account (e.g `environments/global/` can be for identity management at account level)

### Environemnt Configuration
Your `configurations.tf` will look like this:
```
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = YOUR_ACCOUNT
    workspaces {
      name = YOUR_ENV_WORKSPACE
    }
  }
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 4.2.0"
    }
  }
}
```

### Considerations
It is been found useful to seperate your environments based on compartments. Using compartments make it easy to create full isolation and manage 
access based on need. For example, you can create `production` compartment and `stage` compartments, then create two cicd users, each with access to
specific compartment. This way you can manage your environments based on compartemtns with different credentials.

To create different environments (prod, uat, dev), it is assumed that they same overall design.

1. Create a new folder under environments dir, and create `configurations.tf` file to configure how you want to manage your Terraform state.
2. Create the `.auto.tfvars` file and fill it with the needed variables.
3. customise the environment as you wish in the `maint.tf`. You probably want to configure the instances you want to create + security groups per environment.
4. Ensure you do not have an overlapping CIDR for your VCN if you plan to do VCN peering between different environments

### Advantage of using the above approach:
1. You can seperate your cloud access to your cicd pipelines based on environments.
2. Easier to manage different environments
3. Easier to create duplicated environments

## Getting Started
1. Create a directory under `environments`.
1. cd to `environments/DESIRED_ENV` (e.g `environments/stage`)
1. cp `variables.tf`from current working directory to `environments/DESIRED_ENV`
1. pass in the required variables as specified in `variables.tf` in a file called `.auto.tfvars`.
1. Setup your oracle credentials as explained in [Generating an API Signing Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm).
1. (if you plan to use remote state store) Ensure you have setup your Terraform creds for `configurations.tf` file
1. run `terraform plan`
1. if happy run `terraform apply` 

## Modules
|                              module                              | Description                                                                                                             |
| :--------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------- |
|         [common-config](modules/common-config/README.md)         | Contains common configuration that can be used between other modules, such as IDs for computing shape, os versions, etc |
|                 [vault](modules/vault/README.md)                 | Create Vault and manages keys                                                                                           |
|   [file-storage-systme](modules/file-storage-system/README.md)   | Create a file storage system with exports, export paths and mount targets in a given VCN                                |
|              [identity](modules/identity/README.md)              | IAM management, compartment and policies for creating users, groups, compartments, and policies                         |
|             [instances](modules/instances/README.md)             | Create compute instances and attach a network security group id in a given subnets and VCN                              |
|               [volumes](modules/volumes/README.md)               | Create Volumes, Backup Policy and manages volumes attachments                                                           |
|            [kuberentes](modules/kubernetes/README.md)            | Creates k8s cluster and node pools in the given VCN                                                                     |
|         [load-balancer](modules/load-balancer/README.md)         | WIP - Not ready                                                                                                         |
|                 [mysql](modules/mysql/README.md)                 | Creates MYSQL Database in a given VCN                                                                                   |
|               [network](modules/network/README.md)               | Creates a VCN with default routing table, and **default** security list alongside desired subnets                       |
| [network-load-balancer](modules/network-load-balancer/README.md) | Creates an NLB, with listeners and backends alongside backendset in a given VCN                                         |
|            [network-sg](modules/network-sg/README.md)            | Creates network security groups                                                                                         |
|        [object-storage](modules/object-storage/README.md)        | Creates object storage buckets                                                                                          |
|             [public-ip](modules/public-ip/README.md)             | Creates a reserved public IP that can be attached to instances or load balancers                                        |
|         [security-list](modules/security-list/README.md)         | Creates network security lists                                                                                          |
|                   [waf](modules/waf/README.md)                   | Creates a WAF.                                                                                                          |

# Releases

## oci provider version
| repo release | oci terraform provider version |
| :----------: | :----------------------------- |
|     v1.0     | 4.20.0                         |
|     v2.0     | 4.44                           |

## Using the module in your project from github.com:
As explained in [Terraform Modules](https://www.terraform.io/docs/language/modules/sources.html#github), you can use this repo to refer to the modules defined here. Since all modules are hosted in the same git repo, you can the `special double-slash` syntax as stated [here](https://www.terraform.io/docs/language/modules/sources.html#modules-in-package-sub-directories). You can also set specific version using `ref` argument.

In summary:
* Use `github.com/Binsabbar/oracle-cloud-terraform` as source
* Set module name in the path by appending `special double-slash`: `github.com/Binsabbar/oracle-cloud-terraform//modules/identity`
* Set `ref` if you want to avoid breaking changes: `github.com/Binsabbar/oracle-cloud-terraform//modules/identity?ref=vx.x`

Example
```
module "identity" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/identity?ref=v2.0"
  ...
  ...
}

module "object-storage" {
  source = "github.com/Binsabbar/oracle-cloud-terraform//modules/object-storage?ref=v2.1"
  ...
  ...
}

```

# Contributors
Thanks to the following folks for providing suggestions and improvments to this project.
* Abdullah Aljubayri [Thwwaq](https://github.com/Thwwaq) (waf module)
* Abeer Alotaibi [octopus20](https://github.com/octopus20) (network-load-balancer module)
* Grzegorz M [grzesjam](https://github.com/grzesjam) (v1.0 public-ip module)
* Mateusz Kozakiewicz [mateuszkozakiewicz](https://github.com/mateuszkozakiewicz) (v1.0 public-ip module)