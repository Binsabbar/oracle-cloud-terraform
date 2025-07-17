# OCI Bastion Service Terraform Module

A comprehensive Terraform module for managing Oracle Cloud Infrastructure (OCI) Bastion Service with support for both OKE (Oracle Kubernetes Engine) node pools and compute instances.

## Features

- **Multi-target Support**: Connect to both OKE cluster nodes and compute instances
- **Flexible Node Selection**: Support for selecting specific nodes by index, name, or "all"
- **Session Management**: Automated SSH session creation with configurable TTL
- **User Management**: Support for multiple SSH users with different public keys
- **Connection Utilities**: Pre-generated SSH commands and connection information

## Architecture

This module creates:
- A single OCI Bastion Service instance
- Multiple managed SSH sessions based on your configuration
- Automatic discovery of OKE nodes and compute instances
- Connection commands for easy access

## Usage

### Basic Example

```hcl
module "bastion" {
  source = "./path-to-this-module"

  bastion_name       = "my-bastion"
  compartment_id     = "ocid1.compartment.oc1....."
  target_subnet_id   = "ocid1.subnet.oc1....."
  
  # Optional: For OKE cluster access
  cluster_id         = "ocid1.cluster.oc1....."
  
  allowed_ips        = ["10.0.0.0/16", "192.168.1.0/24"]
  
  ssh_public_keys = {
    "developer" = "ssh-rsa AAAAB3NzaC1yc2E... developer@company.com"
    "admin"     = "ssh-rsa AAAAB3NzaC1yc2E... admin@company.com"
  }
  
  bastion_sessions = {
    "oke-workers" = {
      active        = true
      type          = "oke"
      pool_name     = "worker-pool"
      nodes         = ["all"]  # or ["0", "1"] or ["node-name"]
      user          = "developer"
      os_user       = "opc"
      port          = 22
      time          = 180  # minutes
    }
    
    "app-servers" = {
      active          = true
      type            = "compute"
      instance_names  = ["app-server-1", "app-server-2"]
      compartment_id  = ""  # Uses module compartment_id if empty
      user            = "admin"
      os_user         = "opc"
      port            = 22
      time            = 120  # minutes
    }
  }
}
```

### OKE-Only Configuration

```hcl
module "oke_bastion" {
  source = "./path-to-this-module"

  bastion_name     = "oke-bastion"
  compartment_id   = "ocid1.compartment.oc1....."
  target_subnet_id = "ocid1.subnet.oc1....."
  cluster_id       = "ocid1.cluster.oc1....."
  
  allowed_ips = ["10.0.0.0/8"]
  
  ssh_public_keys = {
    "devops" = file("~/.ssh/id_rsa.pub")
  }
  
  bastion_sessions = {
    "worker-nodes" = {
      active    = true
      type      = "oke"
      pool_name = "worker-pool"
      nodes     = ["all"]
      user      = "devops"
      os_user   = "opc"
      port      = 22
      time      = 240
    }
  }
}
```

### Compute-Only Configuration

```hcl
module "compute_bastion" {
  source = "./path-to-this-module"

  bastion_name     = "compute-bastion"
  compartment_id   = "ocid1.compartment.oc1....."
  target_subnet_id = "ocid1.subnet.oc1....."
  
  allowed_ips = ["192.168.0.0/16"]
  
  ssh_public_keys = {
    "sysadmin" = "ssh-rsa AAAAB3NzaC1yc2E... sysadmin@company.com"
  }
  
  bastion_sessions = {
    "web-servers" = {
      active          = true
      type            = "compute"
      instance_names  = ["web-01", "web-02", "web-03"]
      user            = "sysadmin"
      os_user         = "ubuntu"
      port            = 22
      time            = 120
    }
  }
}
```

## Input Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `bastion_name` | `string` | Name of the bastion service |
| `compartment_id` | `string` | OCID of the compartment |
| `target_subnet_id` | `string` | OCID of the target subnet |
| `allowed_ips` | `list(string)` | List of CIDR blocks allowed to connect |
| `ssh_public_keys` | `map(string)` | Map of user names to SSH public keys |
| `bastion_sessions` | `map(object)` | Session configurations (see below) |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_id` | `string` | `""` | OKE cluster OCID (required for OKE sessions) |
| `max_session_ttl_seconds` | `number` | `10800` | Maximum session TTL in seconds |

### Session Configuration

Each session in `bastion_sessions` supports the following structure:

```hcl
{
  active          = bool           # Whether the session is active
  type            = string         # "oke" or "compute"
  user            = string         # User name (must exist in ssh_public_keys)
  os_user         = string         # Target OS username
  port            = number         # Target port (usually 22)
  time            = number         # Session TTL in minutes
  
  # For OKE sessions
  pool_name       = string         # OKE node pool name
  nodes           = list(string)   # Node selection: ["all"], ["0", "1"], or ["node-name"]
  
  # For compute sessions
  instance_names  = list(string)   # List of compute instance names
  compartment_id  = string         # Instance compartment (optional, uses module compartment_id if empty)
}
```

## Outputs

### Connection Information

- **`bastion_id`**: Bastion service OCID
- **`bastion_name`**: Bastion service name
- **`bastion_state`**: Bastion service state

### Session Details

- **`session_connection_info`**: Grouped connection information by session name
- **`session_details`**: Detailed information for each session
- **`ssh_commands`**: Ready-to-use SSH commands for each session
- **`active_sessions_summary`**: Summary statistics of active sessions

### Example Output Usage

```hcl
# Get SSH command for a specific session
output "ssh_to_first_worker" {
  value = module.bastion.ssh_commands["oke-workers-node-0"]
}

# Get connection summary
output "bastion_summary" {
  value = module.bastion.active_sessions_summary
}
```

## Connection Methods

### Method 1: Direct SSH (Recommended)

Use the pre-generated SSH commands from the `ssh_commands` output:

```bash
# Example output command
ssh -o ProxyCommand="oci bastion session create-port-forwarding --session-id ocid1.session.oc1.... --local-port %p --remote-port 22" opc@localhost
```

### Method 2: Port Forwarding

Create a port forwarding session manually:

```bash
# Create port forwarding
oci bastion session create-port-forwarding \
  --session-id ocid1.session.oc1.... \
  --local-port 2222 \
  --remote-port 22

# Connect via SSH
ssh -p 2222 opc@localhost
```

## Node Selection Options

### For OKE Sessions

- **`["all"]`**: Connect to all nodes in the pool
- **`["0", "1", "2"]`**: Connect to specific nodes by index
- **`["node-name-1", "node-name-2"]`**: Connect to specific nodes by name

### For Compute Sessions

- **`instance_names`**: List of compute instance display names

## Requirements

- **Terraform**: >= 0.14
- **OCI Provider**: >= 4.0
- **OCI CLI**: Configured with appropriate permissions
- **Permissions**: 
  - `BASTION_MANAGE` on target compartment
  - `BASTION_SESSION_CREATE` on bastion service
  - `INSTANCE_READ` on compute instances (if using compute sessions)
  - `CLUSTER_READ` on OKE cluster (if using OKE sessions)

## Security Considerations

- **Network Security**: Ensure `allowed_ips` are restricted to trusted networks
- **SSH Keys**: Use separate SSH keys for different users and rotate regularly
- **Session TTL**: Set appropriate session timeouts based on your security requirements
- **Monitoring**: Enable OCI logging and monitoring for bastion access

## Troubleshooting

### Common Issues

1. **Session Creation Fails**
   - Check if the target instances are in RUNNING state
   - Verify SSH public key format
   - Ensure proper IAM permissions

2. **SSH Connection Fails**
   - Verify the OCI CLI is configured and authenticated
   - Check if the bastion service is active
   - Ensure target subnet allows SSH traffic

3. **OKE Node Discovery Issues**
   - Verify cluster_id is correct
   - Check if node pool exists and has running nodes
   - Ensure proper OKE permissions

### Debug Commands

```bash
# Check bastion service status
oci bastion bastion get --bastion-id <bastion-id>

# List active sessions
oci bastion session list --bastion-id <bastion-id>

# Check session details
oci bastion session get --session-id <session-id>
```