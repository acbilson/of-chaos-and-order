+++
title = 'Build your own CI/CD pipeline'
date = 2022-05-05
draft = false
lastmod = 2023-03-14
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['deployment', 'ansible', 'redis', 'ci/cd', 'systemd', 'git', 'podman']
aliases = ['/plants/technology/build-your-own-ci-cd-pipeline/']
+++
**A CI/CD pipeline does not need to begin with Kubernetes, a managed
platform, or a large orchestration layer. For a small self-hosted stack,
Git, Ansible, Redis, Podman, and systemd can provide a deployment system
that is simple enough to understand and reliable enough to operate.**

My self-hosted DevOps pipeline began with an attempt to [architect a
personal DevOps
pipeline](/writings/software-development/architect-a-personal-devops-pipeline/)
and later moved into the Podman era when I wrote about how to [host
services with
Podman](/writings/software-development/host-your-services-with-podman/).
Inspired by Christian Ştefănescu's design for a [Tiny CI
System](https://www.0chris.com/tiny-ci-system.html), I built a minimal
deployment system for my own web stack.

This is not a replacement for a full CI platform. It does not provide a
rich web UI, distributed runners, sophisticated permissions, secrets
management, test matrices, or deployment approvals. That is the point.
For a small personal production environment, I wanted something with a
small operational surface area: push to a Git remote, enqueue a build,
build the container image, and restart the service.

The architecture is intentionally plain:

1. Ansible configures the server.
2. A bare Git repository receives pushes.
3. A `post-receive` hook writes a job into Redis.
4. A small worker script consumes jobs from the queue.
5. The repository's build script creates a Podman image.
6. systemd manages the running service.

The value of this design is not novelty. It is ownership. Every moving
piece is visible, replaceable, and small enough to debug over SSH.

## Step 1: SSH Access

The first step is to configure the server so it can be reached over SSH.
I will not repeat the standard SSH setup process here, but this is the
foundation for the rest of the pipeline. The deployment host needs a
known user, key-based authentication, and enough access to run the
Ansible playbooks that configure the machine.

This step is also where the security posture begins. A self-hosted
pipeline should not depend on password login, unknown users, or broad
manual access. If the only way to operate the system is to SSH into the
box and improvise as root, the pipeline is already too fragile.

## Step 2: Server Configuration

Once SSH access is working, I run an Ansible playbook for the web and
deployment server. This playbook installs common administration tools,
configures Nginx, enables the firewall, installs Podman and Redis, and
places the small scripts that support the CI/CD process.

{{< aside >}}
Steve Owens' article on [Ansible Git Server
Installation](https://opensource.com/article/17/8/ansible-environment-management)
was useful when I first put these pieces together.
{{< /aside >}}

Ansible matters here because it makes the server reproducible. I do not
want a production environment whose behavior only exists in my shell
history. The playbook becomes both documentation and enforcement: if I
need to move to a new server, I can rebuild the deployment substrate
instead of rediscovering it manually.

## Step 3: Chaos Suite Installation

With the server configured, I run a second Ansible playbook to install
the roles for my chaos suite. This step installs proxy configuration,
systemd unit files, bare Git repositories, and the `post-receive` hooks
that interact with the Redis-backed CI/CD service.

Separating the base server configuration from application installation
keeps the boundary clear. The first playbook answers, "What does this
machine need in order to operate as a deployment host?" The second
answers, "Which services should this host run, and how should they be
deployed?"

That distinction is useful even on a single machine. It leaves room to
move services later without turning every Ansible role into a knot of
machine-specific assumptions.

## Step 4: Add Git Remote

The final setup step is to configure the local repository to push to the
new remote. After that, deployment becomes a normal Git operation.

The goal is not to make production casual. The goal is to make the
release path boring and repeatable. A deployment mechanism should reduce
the number of manual decisions required at the moment of release.

## How It Works

Suppose I am working on `chaos-micropub`. I finish a feature, merge it
into the deployment branch, and push that branch to the CI/CD-enabled
remote. In this setup, the deployment branch is `master`.

```sh
git push pi master
```

The remote returns a message like this:

{{< aside >}}
started job 0d313b1e-cca8-11ec-8c59-67453021b8a9 for chaos-micropub.
{{< /aside >}}

The `post-receive` hook adds a job to a Redis queue and writes the job
metadata into a Redis hash. The important values are the timestamp, Git
ref, revision, and repository name. That gives the worker enough
information to build the exact revision that was pushed.

A `tiny-ci.sh` worker waits for queue updates. When it receives a job, it
loads the metadata, changes to the repository directory, checks out the
requested revision, and runs the repository's standardized `ci-build.sh`
script. That build script produces a Podman image and can perform any
repository-specific build steps.

When the build completes, the worker updates the Redis hash with status
and output values. That gives me a small audit trail without introducing
a database, web app, or external deployment service.

The important design choice is that the CI worker does not need to know
how every service builds. It knows how to fetch a revision and call the
standard build entry point. Each repository owns its own build details.

## A Note About Nonroot Containers

The pipeline works most cleanly with root-managed containers, but nonroot
Podman containers introduce a service-restart boundary. I could build the
image automatically, but restarting a user-level systemd service from the
CI worker was not straightforward.

systemd supports user-specific unit files, which is a good fit for
user-owned Podman containers. The problem is that a script running
outside the user's active session does not automatically have the same
runtime environment as that user. A command like this fails:

```sh
systemctl --user restart container-micropub
```

The errors reference `XDG_RUNTIME_DIR` and `DBUS_SESSION_BUS_ADDRESS`.
Running `loginctl enable-linger ${user}` allows user services to start
at boot, but it does not fully solve this restart path. The issue is not
only whether the service can exist without an interactive login. It is
also whether the calling process has the right user session and D-Bus
context to talk to the user service manager.

There may be ways to solve this with more systemd plumbing, but for this
pipeline I chose the conservative boundary: build automatically, then
restart the nonroot service manually from my own SSH session.

That limitation is worth naming because small systems should be honest
about their edges. A deployment tool that silently half-deploys is worse
than a deployment tool with a clear manual step.

## Additional Steps For Ease-of-Use

I originally expected to need a web UI for build status. For now, the CLI
has been enough.

Checking the status of a build is a direct `redis-cli` call:

```sh
ssh pi@web redis-cli hgetall c9a00824-d5fa-11ec-b339-27be07fe7dfd
```

If the build succeeds, I can copy the Podman image hash from the output
and restart the user-level service from my terminal session:

```sh
ssh pi@web systemctl --user restart container-micropub
```

As a final check, I can verify that the production container is using the
newly built image:

```sh
ssh pi@web 'podman inspect webhook | jq .[].Image'
```

This is not elegant, but it is operationally clear. I can see the job, I
can see the image, and I can verify what production is running.

## Conclusion

I expected my personal DevOps pipeline to end with Kubernetes. Instead,
the useful endpoint was a smaller system I could fully understand:
Ansible for reproducible server configuration, Git for release intent,
Redis for a tiny job queue, Podman for image builds, and systemd for
service management.

That does not make Kubernetes wrong. It makes it unnecessary for this
scale of problem. The right deployment architecture is not the most
impressive one; it is the one whose failure modes you can understand and
whose operational cost you are willing to pay.

I keep my Ansible deployments public. You may find them on GitHub
[here](https://github.com/acbilson/chaos-deploy).
