Ansible deployment for a Debian 12 host with Podman and nginx preinstalled.

Usage:

1. Update `inventory/hosts.yml` with the target host and SSH user.
2. Update `inventory/group_vars/web.yml` with the container image and domain names.
3. Run:

```sh
cd deploy
ansible-playbook playbooks/site.yml
```

The playbook:

- pulls the container image
- replaces the running Podman container
- installs an nginx reverse proxy config
- validates nginx config and reloads nginx

This deployment path assumes the image itself runs the Hugo site process and listens on port `6300`.

