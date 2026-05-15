+++
title = 'Deploy a web service with ansible'
date = 2020-07-29
draft = false
lastmod = 2022-05-12
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['ansible', 'systemd']
aliases = ['/plants/technology/deploy-a-web-service-with-ansible/']
+++
I’ve been self-hosting my blog for nearly six months, and it’s become
such a fun outlet that I want to be sure I could replicate it were
something to happen. The source code is easy to store with tools like
git, but I’ve felt increasingly uncertain that I’ll remember all my
server configurations if I needed to deploy my site to a fresh box. At
last, a real-world reason to learn an infrastructure-as-code tool!

There are numerous options - Puppet, Chef, Terraform, Ansible - and not
all of them fit my use-case, but in the end, I chose Ansible because it
was a Python executable which meant I could use one of my favorite dev
tools, virtualenv, to ensure a siloed, reproducible Ansible deployment
setup. I love sandbox tools like docker and virtualenv because I never
know what OS I’ll be running next. Also, I didn’t want to shift the
config complexity from my webserver to my deployment infrastructure.

From my first successful deployment, I’ve been extremely satisfied with
Ansible. The module documentation is clear, the roles run fast enough,
and it’s [idempotent](https://www.wordnik.com/words/idempotent). But
most importantly, it meets my need to have complete documentation for
every configuration on my webserver. But let me stop gushing about it
and show you some examples!

My first foray into the Ansible documentation led me to think that
learning adhoc commands would be a good start, then playbooks, and
finally roles. After a bit of tinkering; however, I realized that roles
were conceptually simpler and fit the mental model I wanted - a
description of various responsibilities a server might provide. For
example, a server might offer web services, and an Ansible role should
describe all the steps to convert any server into a webserver. An
unexpected side effect of this mental model is that it’s led me to
maintain functional distinctions that could be deployed to separate
machines, even though at the moment it all resides on a single machine.

{{< aside >}}
Caveat: I'm going to choose a role I developed a few steps after the
first. It's easier to describe and thus a better candidate for an
example.
{{< /aside >}}

After I’d established the bedrock roles I wanted for the webserver
that’s hosting this site, I began to ponder what it’d take to automate
the static site deployment. I’d read that others used Netlify tools to
automate their site deployment so that they could add content without
manually executing the commit-build-deploy steps. I didn’t want to move
to Netlify today, so I needed a way to achieve what Netlify does on my
own.

The crux of the automation lies in responding to Github webhooks. If I
automate the creation of new content to my Github repository, I need to
receive a notification that the git push has occurred so that I can pull
down the latest code, build, and deploy. I played with writing my server
to accomplish this, but in the process, I discovered a handy package
from `adnahn` called [webhook](https://github.com/adnanh/webhook). Now I
have a process, the commit-build-deploy steps, and a role, the webhook
server. Let’s take a look at the Ansible tasks!

The first step was simple; the webhook package should be installed on
the machine.

```
- name: installs webhook server
  apt:
    name: webhook
    state: latest
  become: yes
```

{{< aside >}}
You'll notice many tasks end with \`become: yes\`. This line indicates
that the command requires heightened privileges to run.
{{< /aside >}}

Somehow, the package doesn’t create it’s own /etc folder, so I take that
step myself.

```
- name: creates and sets hooks directory permissions
  file:
    path: /etc/webhook
    state: directory
    owner: root
  become: yes
```

Why did I need an /etc folder? To put my hook configuration in, of
course! This copies the file from my machine to my target.

```
- name: adds hooks.json
  template:
    src: hooks.json
    dest: /etc/webhook/hooks.json
    owner: root
  become: yes
```

The webhook project responds to incoming webhooks by running shell
scripts. I need somewhere to store them, so I create a folder in
/usr/lib.

```
- name: creates and sets scripts directory permissions
  file:
    path: /usr/lib/webhook/scripts
    state: directory
    owner: root
  become: yes
```

With my folder created, it’s time to copy the three scripts I need for
the commit-build-deploy process. This might have been wrapped into one
iterative task (or compiled into a single script), but I wasn’t sure at
the time whether I’d want a different configuration for any of the
files. In my experience, it’s better to have some duplication where I’m
uncertain of change than to prematurely optimize and split later.

```
- name: adds script to create a new note
  template:
    src: new-note.sh
    dest: /usr/lib/webhook/scripts/new-note.sh
    owner: root
    mode: '0744'
  become: yes

- name: adds script to pull from github
  template:
    src: git-pull.sh
    dest: /usr/lib/webhook/scripts/git-pull.sh
    owner: root
    mode: '0744'
  become: yes

- name: adds script to deploy an update
  template:
    src: git-deploy.sh
    dest: /usr/lib/webhook/scripts/git-deploy.sh
    owner: root
    mode: '0744'
  become: yes
```

With all the webhook installation complete, it’s time to proxy the
server with Nginx.

```
- name: adds nginx proxy config
  template:
    src: webhook_proxy
    dest: /etc/nginx/sites-available/webhook_proxy
  become: yes
  notify: restart nginx

  - name: enables nginx proxy config
  file:
    src: /etc/nginx/sites-available/webhook_proxy
    dest: /etc/nginx/sites-enabled/webhook_proxy
    state: link
```

Did you catch the `notify: restart nginx` line? This refers to another
task which should be executed after this completes, but only when
there’s been a change. It’s nothing fancy.

```
- name: restart nginx
  service:
    name: nginx
    state: restarted
  become: yes
```

One last step to finish the proxy. I need to allow the webhook port
through my firewall.

```
- name: allows webhook port access
  ufw:
    rule: allow
    port: '6237'
    proto: tcp
  become: yes
```

There seem to be as many instructions for running a Linux service as
there are Linux distros. I chose to create a systemd service to manage
my webhook executable, but if you have a better idea, I’d love to hear
it. I particularly want something efficient, fault-tolerant, and works
on Debian.

```
- name: adds systemd script to run webhooks
  template:
    src: webhook.service
    dest: /lib/systemd/system/webhook.service
    owner: root
    mode: '0644'
  become: yes
  notify:
    - reload daemon
    - start webhook service

- name: reload daemon
  shell:
    cmd: systemctl daemon-reload
  become: yes

- name: start webhook service
  shell:
    cmd: systemctl enable --now webhook.service
  become: yes
```

One of my next steps is to begin these tasks with better security
configurations. The webhook server should run as a non-privileged user
with permission only to what it requires. A couple of tasks to create a
user and group, then ownership changes where I add new files and
modifications to existing directories ought to do it.

Once I feel more comfortable with the security posture, I’d like to
extrapolate more of the configuration to a separate file that I can
configure per execution. Wouldn’t it be sweet if I could point this
script at a local test Docker image? Then I could be certain that both
my testing and production configuration were identical.
