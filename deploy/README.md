Ansible deployment for a Debian 12 host with nginx installed and a local Podman-based build workflow.

Usage:

1. Update `inventory/hosts.yml` with the target host and SSH user.
2. Update `inventory/group_vars/web.yml` with the site root and domain names.
3. Run:

```sh
cd deploy
ansible-playbook playbooks/site.yml
```

The playbook:

- builds the site locally with the deployment container image
- archives and uploads the rendered static files
- replaces the contents of `/srv/of-chaos-and-order`
- installs an nginx site config that serves that directory directly
- validates nginx config and reloads nginx

The site is served directly from `/srv/of-chaos-and-order` on the remote host.
