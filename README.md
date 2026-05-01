# chaos-template
A starter template for for projects in the chaos family.

While I appreciate build and deployment (Ansible) tools, I've found that most personal projects need minimum operational configuration but maximum flexibility. Even though I often use containers to simplify my build and deployment process, there's always something that needs a little tweaking. Using the most basic tools available, I can get builds to run on any machine, any architecture. Plus it helps me learn :)

## Complete Tool List
- bash
- ssh
- scp
- find
- entr
- egrep
- sort
- awk
- docker/podman
- systemctl
- envsubst
- Makefile
- Dockerfile

## Operation

First, run the SETUP shell script to make the few adjustments post-copy to finish configuring your repository. Once it's been run you may safely delete it.

Everything happens via the Makefile. Run `make` or `make help` to see the list of options and cull them as needed.

The Makefile isolates steps by wrapping them in shell scripts. Each script is broken into dev/uat/prod to specify the unique build, start, stop, clean and test commands for the various environments. This keeps these steps separate and allows for a wide degree of freedom in how I deploy.

Over the years I've made heavier use of the .env file to catalog the changing pieces within my scripts and templates. With nifty tools like `envsubst` I can indempotently output complex configuration files, and the .env becomes the repository's configuration manifest.
