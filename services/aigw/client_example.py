"""
Cloud Run → LiteLLM via Cloudflare Access (Service Token auth).

Required env vars:
  CF_ACCESS_CLIENT_ID      — from: terraform output cf_service_token_client_id
  CF_ACCESS_CLIENT_SECRET  — from: terraform output -raw cf_service_token_client_secret
  LITELLM_MASTER_KEY       — your master key
"""

import os
import httpx

LITELLM_BASE_URL = "https://aigw.labmox.com"

_headers = {
    "CF-Access-Client-Id": os.environ["CF_ACCESS_CLIENT_ID"],
    "CF-Access-Client-Secret": os.environ["CF_ACCESS_CLIENT_SECRET"],
    "Authorization": f"Bearer {os.environ['LITELLM_MASTER_KEY']}",
}

_client = httpx.Client(base_url=LITELLM_BASE_URL, headers=_headers, timeout=60)


def chat(messages: list[dict], model: str = "gpt-4o") -> dict:
    response = _client.post(
        "/chat/completions",
        json={"model": model, "messages": messages},
    )
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    result = chat([{"role": "user", "content": "ping"}])
    print(result["choices"][0]["message"]["content"])
