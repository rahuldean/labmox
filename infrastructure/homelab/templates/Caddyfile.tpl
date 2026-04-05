# Rendered by OpenTofu - push to /etc/caddy/Caddyfile on the proxy LXC.
# See docs/apply-caddyfile.md for instructions.

immich.home {
    reverse_proxy ${docker_ip}:${immich_port}
}

paperless.home {
    reverse_proxy ${docker_ip}:${paperless_port}
}

backrest.home {
    reverse_proxy ${docker_ip}:${backrest_port}
}

vscode.home {
    reverse_proxy ${docker_ip}:${vscode_port}
}
