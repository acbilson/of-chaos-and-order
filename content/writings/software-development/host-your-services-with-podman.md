+++
author = "Alex Bilson"
date = "2021-03-10"
lastmod = "2022-12-16 13:21:05"
toc = true
epistemic = "evergreen"
tags = ["podman","kubernetes","k3s"]
+++
## Recollecting the Journey

My [earlier foray](/writings/software-development/architect-a-personal-devops-pipeline/) into self-hosting a devops pipeline was little more than an Nginx proxy serving up Hugo-generated HTML files. As needs arose I began to add web services. Automated deployments with a webhook server and mobile publishing with a custom publishing service were two of the first. At the time I wrote this post, I was also running a data-publishing service called [datasette](https://github.com/simonw/datasette), deploying server updates with Ansible, and managing all processes with supervisord.

I thought the natural progression was towards Kubernetes, so I attempted to make the transition to [k3s](https://k3s.io/). When I drafted a network diagram, however, I discovered that the CI/CD process I wanted to implement to deploy my Kube nodes would require a second machine, and I didn't want to spend the money or manage the extra configuration. I had attempted an intermediary Podman installation but had run into difficulties configuring Debian Buster since it's not officially supported. But I didn't get very far until I also experienced trouble with k3s and, unwilling to let my site languish for weeks while I tried to implement a deployment process I didn't need, I abandoned the project. Fortunately, after bit of tinkering I _did_ get Podman working. And it's been a dream come true.

## The Podman Era

One of the intermediary transitions I needed to move my services to Kubernetes was to containerize them. I had a few in Docker containers for local development, so it wouldn't take much, but running my production services as containers was a new experience. And it's been such a great experience.

Podman has been a pleasure to operate for three reasons.

- Instead of relying on a mysterious Docker daemon to operate my containers, Podman let me convert each container unit into a systemd service so I can leverage the stability and support of Debian's process management. Systemd services can be enabled to launch on startup and log output to the system journal. It just feels more, integrated.
- Docker didn't have native pod support. I couldn't launch a web service plus database as a single unit without a bit of finagling, or by using Docker Compose. Podman has pods that work identically to pods in Kubernetes and can be operated as a unit with, you guessed it, the systemd service architecture.

## Updated Architecture

## Conclusion

Thanks to [Jeff Geerling's](https://www.jeffgeerling.com/) invaluable YouTube [Cluster Series - Part 1](https://youtu.be/kgVz4-SEhbE), it's evident that I need at least three nodes are necessary before Kubernetes is a worthwhile option. One node is dedicated to operating the cluster and offers little but resource consumption if it's the only node. Two nodes allow for only a single node for the master node to manage - again offering little and supplying no opportunity for Kubernete's container distribution logic. Two nodes for the master node to manage does give Kubernetes the chance to select the best node for a given pod, to have a backup for failed pods, and starts to become tedious to operate independently (barely).

{{< aside >}}
...at least three nodes are necessary before Kubernetes is a worthwhile option.
{{< /aside >}}

Is it time to move to Kubernetes? There's never been a better opportunity to make the attempt but, for my purposes, Podman may be the sweet spot. There's nothing k3s offers that my little Podman cluster can't already do with fewer resources. But with Debian Bullseye moving me closer to a fully supported OS, I might have to try anyways, if only to learn.

## The Final Transition?

Tinkering with my personal devops pipeline has been a wonderful experience. I kinda don't want it to end. Where I'm at today; however, is such a great setup that I may not need more for a while. Decide for yourself by reading my (currently) last installment, [Build your own CI/CD pipeline](/writings/software-development/build-your-own-ci-cd-pipeline/).
