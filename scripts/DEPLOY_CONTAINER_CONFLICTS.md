Deploy: handling container name conflicts on VPS

Summary
-------
If you see errors about a container name already in use (for example, '/asistapp_db' already in use), it usually means a stale container was created outside the 'docker compose' project that CI expects. The CI deploy workflow now detects the conflict and can either fail with instructions or remove the conflicting container when 'deploy_force_recreate' is enabled in the workflow dispatch options.

What CI does now
----------------
- Prior to running `docker compose up`, CI checks for containers with the fixed names we use in our `docker-compose.prod.yml`. The default names are:
  - `asistapp_db` (postgres) — defined as `container_name` in compose

- If a conflicting container is found and the `deploy_force_recreate` input is NOT set, the job fails early and prints instructions to remove the container manually:
  - Connect to the VPS and run: `sudo docker rm -f asistapp_db`
  - Re-run the workflow

- If `deploy_force_recreate` is set to true (via the workflow dispatch input), the job tries to remove the conflicting container(s) automatically before continuing.

How to set `deploy_force_recreate` from the GitHub UI
---------------------------------------------------
1. Open the workflow run page: Actions → Deploy to VPS.
2. Click 'Run workflow'.
3. Set `deploy_force_recreate` to `true` and confirm.

Caveats
------
- Automatically deleting containers might remove other services on the VPS if they were started manually and reuse those names. Use `deploy_force_recreate` with care (it's disabled by default).
- Best practice: avoid `container_name` hard-coded values in production if multiple projects may run on the same host. If possible, use Compose project names (–project) or unique container names per environment.

Manual recovery commands
------------------------
- List containers: `sudo docker ps -a`
- Remove container by name: `sudo docker rm -f asistapp_db`
- Recreate compose with latest image: `sudo docker compose -f docker-compose.prod.yml up -d --force-recreate --no-build`

