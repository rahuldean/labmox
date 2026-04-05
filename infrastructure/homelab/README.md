# homelab-infra

OpenTofu config for spinning up a Proxmox homelab. Deploys LXC containers on a single node - a reverse proxy, DNS server, Docker host, and NAS.


## Prerequisites

1. **OpenTofu 1.6.0 or later**. Install from [opentofu.org](https://opentofu.org).

2. **Proxmox with API token**. Create a token for Terraform:
   - Log in to Proxmox web UI
   - User management → Create a user (e.g., `terraform@pve`) or use an existing user
   - API tokens → Create a token for that user
   - Keep the token secret - you'll need it for `terraform.tfvars`

3. **LXC template in Proxmox**. Download a Debian 12 template:
   - Proxmox web UI → Datacenter → Content
   - Click "Download Templates" and grab Debian 12 Standard
   - Or use the template ID from your storage (e.g., `local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`)

4. **SSH public key** (optional but recommended). You can inject your SSH key into all containers at provision time.

## Usage

### 1. Create a Terraform Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and fill in:
- `proxmox_endpoint` - IP and port of your Proxmox host (e.g., `https://192.168.1.2:8006`)
- `proxmox_username` - API user (e.g., `terraform@pve`)
- `proxmox_password` - API token or password
- `proxmox_node` - Name of the Proxmox node (usually `pve`)
- `network_gateway` - Your router/gateway IP (e.g., `192.168.1.1`)
- `lxc_template` - Full path to the Debian 12 template in Proxmox
- `ssh_public_keys` - Your SSH public key(s) (optional)

### 2. Initialize and Plan

```bash
tofu init
tofu plan
```

Review the output. You should see four containers about to be created.

### 3. Apply

```bash
tofu apply
```

Wait for the containers to be created and boot. This usually takes 2-3 minutes.

### 4. Deploy the Caddyfile (Reverse Proxy Config)

After apply, a file is rendered to `rendered/Caddyfile`. Push it to the proxy container:

```bash
PROXY_IP=$(tofu output -raw proxy_ip)
scp rendered/Caddyfile root@${PROXY_IP}:/etc/caddy/Caddyfile
ssh root@${PROXY_IP} systemctl reload caddy
```

See `docs/apply-caddyfile.md` for more details.

## Key Files

- **`modules/lxc/`** - Reusable module for provisioning any LXC container. Handles CPU, memory, disk, networking, and SSH keys.

- **`*.tf` at root** - One file per service (`proxy.tf`, `pihole.tf`, `docker.tf`, `openmediavault.tf`). Each defines IP, sizing, and container config via `locals`. Services are instantiated with the `module "lxc"` block.

- **`templates/Caddyfile.tpl`** - Caddy reverse proxy config, templated with IPs and ports at apply time. Rendered to `rendered/Caddyfile` and manually pushed to the proxy container.

## Tips

- **Change container sizing**: Edit the `locals` block in each service file (e.g., `cpu_cores`, `memory_mb`). Re-run `tofu plan` and `tofu apply`.

- **Add a service**: Copy one of the `.tf` files, change the hostname, IP, and module name. Add a `locals` block with sizing.

- **SSH into containers**: All containers get your SSH key if you provide it in `terraform.tfvars`. Then `ssh root@192.168.1.XX`.

- **Destroy everything**: `tofu destroy` - containers are deleted from Proxmox.

## Troubleshooting

If containers don't come up:
- Check Proxmox logs: Proxmox web UI → Cluster → Tasks
- Verify network bridge name matches your Proxmox setup (default `vmbr0`)
- Check that the LXC template ID is correct and exists in Proxmox
