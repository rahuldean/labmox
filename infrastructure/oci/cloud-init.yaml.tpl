#cloud-config

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg

write_files:
  - path: /etc/cloudflared/creds.json
    permissions: "0600"
    owner: root:root
    content: |
      {"AccountTag":"${account_id}","TunnelSecret":"${tunnel_secret}","TunnelID":"${tunnel_id}"}

  - path: /etc/cloudflared/config.yml
    permissions: "0644"
    owner: root:root
    content: |
      tunnel: ${tunnel_id}
      credentials-file: /etc/cloudflared/creds.json
      logfile: /var/log/cloudflared.log

runcmd:
  # Docker
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ubuntu

  # Coolify (listens on :8000)
  - curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

  # cloudflared
  - curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg
  - echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflared.list
  - apt-get update
  - apt-get install -y cloudflared
  - cloudflared service install
  - systemctl enable cloudflared
  - systemctl start cloudflared
