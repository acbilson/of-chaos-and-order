+++
title = 'Deploy a web service with Ansible'
date = 2020-07-29
draft = false
lastmod = 2022-05-12
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['ansible', 'systemd']
aliases = ['/plants/technology/deploy-a-web-service-with-ansible/']
+++
**Ansible is most useful when it turns a server from a memory test into a
repeatable system. A good deployment role should document the service,
apply the configuration idempotently, and leave clear operational
boundaries behind.**

After self-hosting my blog for several months, I became less worried
about the source code and more worried about the server. Git already gave
me a durable copy of the site content. What I did not have was a durable
description of the machine: packages, users, permissions, Nginx
configuration, systemd services, firewall rules, and deployment scripts.

That is the problem that made Ansible useful. I did not want to move
configuration complexity from the server into an equally opaque
deployment system. I wanted the server configuration to become explicit,
reviewable, and reproducible.

There are many tools in this space, including Puppet, Chef, Terraform,
and Ansible. I chose Ansible because it fit the scale of the problem. It
could run from a Python environment, did not require a resident agent on
the server, and let me describe configuration in roles that matched how I
thought about server responsibilities.

The role model became the important abstraction. Instead of thinking in
terms of one long setup script, I could describe capabilities: a
webserver role, a webhook role, a service role, a firewall role. Even
when everything lived on one machine, those boundaries made the system
easier to understand and left open the possibility of moving
responsibilities later.

## The Deployment Problem

Once the baseline webserver roles were in place, I wanted to automate the
static-site deployment path. The workflow was straightforward:

1. GitHub receives a content or code update.
2. A webhook notifies my server.
3. The server pulls the latest source.
4. The site is rebuilt and deployed.

I considered writing the webhook server myself, but the
[webhook](https://github.com/adnanh/webhook) package already did the
small piece I needed: receive a webhook and run a configured script. That
gave me a useful role boundary. Ansible would install and configure the
webhook service. Shell scripts would own the commit-build-deploy steps.

The rest of this article walks through the Ansible tasks for that role.

## Install The Package

The first task installs the webhook package:

```yaml
- name: Install webhook server
  ansible.builtin.apt:
    name: webhook
    state: present
    update_cache: true
  become: true
```

I prefer `state: present` for this kind of role unless I intentionally
want every run to upgrade the package. Reproducibility is easier when
routine configuration runs do not also perform surprise version changes.

The `become: true` line marks tasks that require elevated privileges.
That should stay visible. Privilege is part of the operational design,
not just an implementation detail.

## Create Configuration Directories

The package did not create the configuration directory I wanted, so the
role creates it explicitly:

```yaml
- name: Create webhook configuration directory
  ansible.builtin.file:
    path: /etc/webhook
    state: directory
    owner: root
    group: root
    mode: "0755"
  become: true
```

This is one of the places where Ansible reads well: the task is both the
action and the documentation. The directory should exist, should be owned
by root, and should have predictable permissions.

## Template The Hook Configuration

The hook definition belongs in `/etc/webhook`:

```yaml
- name: Add hooks configuration
  ansible.builtin.template:
    src: hooks.json
    dest: /etc/webhook/hooks.json
    owner: root
    group: root
    mode: "0644"
  become: true
  notify: Restart webhook
```

Using `template` instead of `copy` leaves room for environment-specific
values later. The `notify` line is also important. If the hook
configuration changes, the service should restart. If it does not change,
Ansible should leave the service alone.

That is the practical value of idempotence. A deployment role should be
safe to run repeatedly.

## Install Deployment Scripts

The webhook package responds to requests by running shell scripts. I keep
those scripts in a dedicated directory:

```yaml
- name: Create webhook script directory
  ansible.builtin.file:
    path: /usr/lib/webhook/scripts
    state: directory
    owner: root
    group: root
    mode: "0755"
  become: true
```

Then the role installs the scripts:

```yaml
- name: Install webhook scripts
  ansible.builtin.template:
    src: "{{ item }}"
    dest: "/usr/lib/webhook/scripts/{{ item }}"
    owner: root
    group: root
    mode: "0744"
  loop:
    - new-note.sh
    - git-pull.sh
    - git-deploy.sh
  become: true
  notify: Restart webhook
```

I originally wrote these as three separate tasks. That was acceptable
while I was still learning which files might diverge. Once the shape was
clear, the loop made the role easier to read without hiding meaningful
differences. Duplication is not always wrong, but it should have a
reason.

## Proxy With Nginx

The webhook service should not be exposed casually. In this setup, Nginx
owns public ingress and proxies only the route I intend to expose.

```yaml
- name: Add nginx proxy configuration
  ansible.builtin.template:
    src: webhook_proxy
    dest: /etc/nginx/sites-available/webhook_proxy
    owner: root
    group: root
    mode: "0644"
  become: true
  notify: Restart nginx

- name: Enable nginx proxy configuration
  ansible.builtin.file:
    src: /etc/nginx/sites-available/webhook_proxy
    dest: /etc/nginx/sites-enabled/webhook_proxy
    state: link
  become: true
  notify: Restart nginx
```

The handler keeps the restart behavior explicit:

```yaml
- name: Restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
  become: true
```

In a more mature role, I would also validate the Nginx configuration
before restarting. Restarting a reverse proxy with a bad config is a
preventable outage.

## Open The Firewall

The firewall rule should be as narrow as the service allows:

```yaml
- name: Allow webhook port access
  community.general.ufw:
    rule: allow
    port: "6237"
    proto: tcp
  become: true
```

Opening a port is not just a connectivity step. It is part of the threat
model. If the webhook endpoint triggers deployment scripts, it needs
authentication, signature verification, careful script permissions, and
the smallest useful exposure.

## Run The Service With systemd

For Debian, systemd is the right default process manager. It starts the
service at boot, restarts it when configured to do so, and centralizes
logs in the journal.

```yaml
- name: Add systemd unit for webhook
  ansible.builtin.template:
    src: webhook.service
    dest: /etc/systemd/system/webhook.service
    owner: root
    group: root
    mode: "0644"
  become: true
  notify:
    - Reload systemd
    - Restart webhook

- name: Enable webhook service
  ansible.builtin.systemd:
    name: webhook.service
    enabled: true
    state: started
  become: true
```

The handlers should use Ansible modules rather than shell commands:

```yaml
- name: Reload systemd
  ansible.builtin.systemd:
    daemon_reload: true
  become: true

- name: Restart webhook
  ansible.builtin.systemd:
    name: webhook.service
    state: restarted
  become: true
```

Using `ansible.builtin.systemd` communicates the intent more clearly than
shelling out to `systemctl`, and it gives Ansible a better chance to
model the task correctly.

## Security And Testability

The next version of this role should run the webhook service as a
non-privileged user with access only to the files and commands it needs.
That means creating a dedicated user and group, assigning ownership
carefully, limiting script permissions, and making sure the webhook
cannot become a general-purpose command execution endpoint.

I would also move more configuration into variables: port, domain, script
paths, repository paths, and service user. Good variables make the role
portable. Too many variables make the role abstract and hard to reason
about. The line is whether the value represents a real deployment
difference.

For testability, the ideal shape is a role that can target a disposable
local environment before production. Even a lightweight container or VM
test gives confidence that templates render, packages install, handlers
fire, and services start. The point is not to make a personal deployment
feel enterprise-sized. The point is to catch preventable mistakes before
they become production debugging.

## Conclusion

Ansible was useful here because it converted a working server into a
repeatable system. The role installs the package, writes configuration,
places scripts, proxies traffic, opens the firewall, and manages the
process with systemd. More importantly, it records the operational
decisions behind the service.

That is the standard I want from infrastructure as code. It should not
only make setup faster. It should make the system easier to inspect,
safer to rebuild, and clearer to operate when something breaks.
