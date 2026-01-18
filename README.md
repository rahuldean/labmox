# labmox
Repo for packages/libraries, services that are used across my apps. Also contains the IaaC for my homelab.

## Folders
### Infra
IaaC code for homelab, apps and services.

* `infrastructure/homelab` - OpenTofu config for spinning up a Proxmox homelab. Deploys LXC containers on a single node — a reverse proxy, DNS server, Docker host, and NAS.

### Libraries
Shared libraries or packages that are used across my apps/services. Some services/packages will be moved to an open repo soon.

* `libraries/auth-machines` - Library that implements a state machine for typical auth scenarios for my apps, supporting email/password + mfa login mechanisms. TBD opensource & publish to public registry.

### Services
Services that are used by my other apps.

* `services/ai-property-inspector-service` - Go service that is used by rentomator app for analyzing photos submitted by users during inspection. Uses LiteLLM for LLM model, key and cost management. Currently uses Anthropic but can be configured to fall back to vision models from Google/OpenAI.