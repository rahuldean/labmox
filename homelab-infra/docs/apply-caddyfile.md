# Pushing the Caddyfile to the proxy

After running `tofu apply`, a Caddyfile gets written to `rendered/Caddyfile`.
It won't do anything until you push it to the proxy container.

```bash
PROXY_IP=$(tofu output -raw proxy_ip)
scp rendered/Caddyfile root@${PROXY_IP}:/etc/caddy/Caddyfile
ssh root@${PROXY_IP} systemctl reload caddy
```
