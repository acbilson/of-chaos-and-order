+++
title = 'Host your services with Podman'
date = 2021-03-10
draft = false
lastmod = 2022-12-16
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['podman', 'kubernetes', 'k3s', 'systemd', 'containers']
aliases = ['/plants/technology/host-your-services-with-podman/']
+++
**Podman is a useful middle ground between hand-managed Linux services
and a full Kubernetes cluster. It gives small systems container
boundaries without forcing them to adopt more orchestration than they
need.**

My [earlier foray](/writings/software-development/architect-a-personal-devops-pipeline/)
into self-hosting started with Nginx serving a Hugo-generated static
site. As the site grew, I added services around it: a webhook server for
deployment, a publishing service for mobile writing, a
[Datasette](https://github.com/simonw/datasette) instance for data
publishing, Ansible for server configuration, and process management with
supervisord.

That system worked, but it had a natural pressure point. Each service had
its own runtime assumptions, dependency shape, port, user, logs, and
restart behavior. Ansible made the machine reproducible, but I still
wanted cleaner service boundaries. Containers were the obvious next
step.

The tempting answer was Kubernetes, especially [k3s](https://k3s.io/).
But once I mapped the actual system, Kubernetes looked like more platform
than the workload required. I did not need a cluster scheduler to run a
small number of services on one machine. I needed reproducible containers
that still fit the operational model I already understood.

That is where Podman fit.

## Why Podman Fit

Podman gave me most of the container boundary I wanted without requiring
a Docker daemon or a Kubernetes control plane. I could build images, run
containers, group related containers into pods, and manage them with
ordinary Linux tooling.

The daemonless model mattered. With Docker, the daemon becomes another
privileged service that owns container lifecycle. With Podman, containers
can run as ordinary processes under the user that launched them. That
fits a small self-hosted environment where I want fewer privileged
components and clearer ownership.

Rootless containers also matched the security direction I was already
taking. I had been moving services into distinct nonroot users so each
service had less access to the system. Podman made that pattern feel
native rather than bolted on.

## systemd As The Process Manager

The biggest operational win was systemd integration. Podman can generate
systemd unit files for containers and pods, which lets Debian manage
containerized services the same way it manages other long-running
processes.

That matters because systemd already solves several problems I care
about:

1. Start services at boot.
2. Restart services when appropriate.
3. Capture logs in the journal.
4. Express dependencies between services.
5. Expose status through standard system tools.

For a small deployment, that is often enough. I do not need a cluster
scheduler if all I need is reliable process supervision on one machine.
Podman plus systemd keeps the operating model close to Linux instead of
moving it into a separate orchestration layer.

## Pods Without A Cluster

Podman also supports pods, which gave me a useful conceptual bridge
toward Kubernetes without requiring Kubernetes itself. A web service and
its database can be grouped as a unit. They can share a network
namespace, be started together, and be represented as one operational
shape.

That solved a real problem. Docker can get there with Docker Compose,
but Podman's pod model maps more directly to the Kubernetes concepts I
wanted to learn. I could practice the mental model of grouped containers
while still keeping the deployment small.

This is a good example of choosing a tool for both current fit and
future learning. Podman was useful immediately, and it taught concepts
that would transfer if I later moved to Kubernetes.

## Why Not Kubernetes Yet

Jeff Geerling's cluster work helped clarify the threshold. For my
purposes, Kubernetes did not become compelling until there were enough
nodes and services for scheduling, failover, and distribution to matter.
A single-node cluster gives practice, but it does not provide much
operational value beyond the learning itself. Two nodes are still
limited. Three or more nodes begin to make the orchestration model more
credible.

{{< aside >}}
At least three nodes are necessary before Kubernetes becomes a meaningful
operational option for this kind of self-hosted environment.
{{< /aside >}}

That does not make Kubernetes the wrong tool. It makes it the wrong next
tool for this system. Kubernetes solves real problems, but if those
problems are not present, it mostly adds a control plane, configuration
surface, networking model, and failure modes I now have to operate.

Podman gave me the part I actually needed: containerized services with
clear process management.

## The Tradeoff

Podman is not a full platform. It does not give me automatic placement
across nodes, declarative cluster state, service discovery across a
fleet, or built-in deployment workflows. For a larger team or a larger
service estate, those missing pieces matter.

For my personal stack, the omissions were advantages. Fewer moving parts
meant fewer things to learn at the moment of failure. I could inspect a
unit file, read the journal, run `podman ps`, rebuild an image, and
restart a service without asking a cluster why it made a scheduling
decision.

The result was not more sophisticated than Kubernetes. It was more
appropriate.

## Conclusion

Podman became the right container layer for this stage of the system. It
let me move services into containers, preserve the systemd-based
operational model, run services under nonroot users, and learn pod-shaped
deployment without committing to a cluster.

The larger lesson is the same one that shaped the rest of this DevOps
series: adopt the next tool that solves the next real problem. For this
system, the next problem was service isolation and container packaging,
not cluster orchestration. Podman solved that problem with fewer moving
parts.

The next step was automating deployment around that smaller architecture.
That became [Build your own CI/CD pipeline](/writings/software-development/build-your-own-ci-cd-pipeline/).
