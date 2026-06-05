+++
title = 'Use the minimum number of machines'
date = 2022-01-28
draft = false
lastmod = 2023-04-06
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['architecture', 'efficiency', 'scalability', 'kubernetes']
aliases = ['/plants/technology/use-the-minimum-number-of-machines/']
+++
**Use the minimum number of machines that satisfies the real operational
requirement. Every additional machine adds capacity, but it also adds
coordination, networking, deployment, monitoring, security, and failure
modes.**

This matters whether you are hosting a personal service or launching
entrepreneurial software. Modern infrastructure culture makes it easy to
assume a serious system should begin with clusters, regions,
microservices, queues, service meshes, and automated rescheduling. Those
tools are powerful, but they are not free. They create an operating model
that someone has to understand, secure, debug, and pay for.

The professional move is not to reject distributed systems. It is to
earn them.

## Complexity Has A Carrying Cost

Kubernetes creates a strong temptation here. Because it is common in the
industry, it can feel like the responsible default. But Kubernetes is not
just a better process supervisor. It is closer to “a general-purpose
cluster operating system kernel”
([ButtonDown](https://buttondown.email/nelhage/archive/two-reasons-kubernetes-is-so-complex/)).
That is a remarkable tool when you need a cluster operating system. It
is an expensive tool when you only need to run a web service, a database,
and a background worker.

The cost is not only CPU, memory, or cloud spend. The cost is cognitive.
You now need to reason about nodes, pods, deployments, services,
ingress, secrets, persistent volumes, network policy, scheduling, health
checks, and controller behavior. Each of those abstractions can be
useful. Each can also become one more place where a simple outage hides.

A smaller system has a major advantage: when it fails, the causal chain
is shorter. You can inspect the process, read the logs, check the disk,
restart the service, and understand the result. That directness is an
engineering asset, not a lack of sophistication.

## One Machine Can Do More Than You Think

Engineers routinely underestimate the capacity of a single well-used
machine. A mid-size VM can serve a surprising amount of traffic when the
application is simple, the database is local or well-tuned, caching is
reasonable, and the code avoids obvious waste. [David
Crawshaw](https://crawshaw.io/blog/one-process-programming-notes) notes
how a few performance adjustments can enable startup software to handle
many thousands of requests per second on one mid-size cloud VM.

That does not mean every workload belongs on one server. It means the
burden of proof belongs on expansion. If a system is slow, the first
question should not be, “How many nodes do we need?” It should be, “What
is the bottleneck?” The answer might be a bad query, an unbounded queue,
an inefficient serialization path, a missing index, synchronous network
calls, or a deployment process that restarts more than necessary.

Adding machines before answering that question can hide poor design for
a long time. It can also make the design harder to fix because the
performance problem is now distributed across more components.

## Distribution Does Not Equal Optimization

Large companies create another distortion. Engineers see the public
architecture of Google, Amazon, Netflix, or Meta and infer that serious
software should imitate their infrastructure shape. But those companies
have problems most teams do not have: global traffic, strict latency
budgets, high deployment volume, many teams, enormous data sets, and
business risk that justifies specialized platform teams.

Even then, distribution does not automatically produce efficiency. A
service can be spread across thousands of machines and still waste
resources because of poor memory layout, chatty network calls, excessive
serialization, or bad cache boundaries. Scaling out can be the right
answer, but it is not a substitute for understanding the system.

Frank McSherry, Michael Isard, and Derek G. Murray explore this problem
in their paper on the cost of scalability. They open with a useful
discipline:

{{< quote source="[Paul Barham](https://www.usenix.org/system/files/conference/hotos15/hotos15-paper-mcsherry.pdf)" >}}
You can have a second computer once you’ve shown you know how to use the
first one.
{{< /quote >}}

That is the posture I want in infrastructure decisions: not minimalism
as an ideology, but evidence before expansion.

## The Real Caveat Is Availability

Valeriano Manassero raised the right caveat to this argument: many
business systems have redundancy and service-level requirements that one
machine cannot satisfy.

{{< quote source="[Valeriano Manassero](https://indieweb.social/@vmanassero@mastodon.online/110150335148727840)" >}}
@acbilson while I agree many applications don’t need a lot of compute
power, almost every business project have specific SLA that can be
guaranteed with, at least, two different set of nodes that may have also
their specific requirements. I’m not saying you are wrong but just
missing a topic usually discussed a lot during infrastructure design.
{{< /quote >}}

That is correct. Availability changes the calculation.

Many failures are machine-level failures: hardware faults, kernel
issues, host networking problems, disk exhaustion, bad security updates,
and cloud provider incidents. If the service must remain available
through those events, one machine is no longer enough. A process
supervisor can restart a crashed application, but it cannot restart a
dead host from inside the dead host.

Even so, redundancy should be sized to the requirement. If a service can
be down for a few minutes, a warm standby and DNS failover may be
sufficient. If a service has contractual uptime requirements, active
replication, load balancing, tested failover, backups, monitoring, and
incident procedures become part of the system. At that point, more
machines are justified because the requirement changed from “run this
service” to “survive this class of failure.”

That distinction matters. You do not add machines because the system
feels more professional with them. You add machines because you can name
the failure mode, the recovery objective, and the operational process
that the extra machine enables.

## A Practical Rule

Start with the smallest architecture that can satisfy the current
product, security, and availability requirements. Then expand when one
of those requirements becomes concrete.

Useful triggers include:

1. The measured load exceeds what one tuned machine can handle.
2. The business requires availability through host failure.
3. The deployment process needs zero-downtime rollouts.
4. The data model requires geographic proximity or separation.
5. The team structure requires independent service ownership.
6. The security model requires stronger isolation than one host can
   provide.

Those are engineering reasons. They can be evaluated, tested, and
explained. “Everyone uses Kubernetes” is not an engineering reason.

## Conclusion

The minimum number of machines is not always one. It is the fewest
machines that honestly satisfy the system's load, availability,
security, and operational requirements.

For many early systems, that number is smaller than the industry implies.
A single machine, operated carefully, can carry more product learning
than a premature cluster. It keeps the feedback loop short, the failure
surface understandable, and the infrastructure budget honest.

When the second machine becomes necessary, add it deliberately. Know
what problem it solves. Know how failover works. Know how it is patched,
monitored, secured, backed up, and restored. The goal is not fewer
machines as an ideology. The goal is infrastructure that is as simple as
the problem allows and as robust as the business requires.
