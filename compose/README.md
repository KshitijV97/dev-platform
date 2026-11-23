# Compose stack

The stack is deliberately small:

| Service | Purpose |
|---|---|
| `caddy` | TLS and reverse proxy |
| `app` | Placeholder for the real web service |
| `postgres` | Database |
| `uptime-kuma` | On-box uptime dashboard |
| `dozzle` | Read-only container log viewer |

## Smoke test

```bash
cp .env.example .env
# edit DOMAIN and POSTGRES_PASSWORD
docker compose -f compose/compose.yaml --env-file .env up -d
```

The default `app` image is `nginx:alpine`, so `https://$DOMAIN` serves the nginx welcome page. Replace `APP_IMAGE` with the real image and adjust the upstream port in `Caddyfile`.

## Notes

- `status.$DOMAIN` and `logs.$DOMAIN` need DNS records. Caddy will request certificates for each.
- Postgres is not published to the host. Use `docker compose exec postgres psql` for access.
- Dozzle mounts the Docker socket read-only. Treat access to `logs.$DOMAIN` as admin access.
- Log rotation is 10 MB × 3 per container. Increase only with a disk-space alert in place.
- Pin image digests before production. The tags here are for a scaffold.
