set shell := ["/opt/homebrew/bin/fish", "-c"]

## builds a podman image. Options are: hugo, firewithin
build:
	podman build -f build/Dockerfile -t acbilson/of-chaos-and-order:latest .

verify: build
	podman run --rm \
		--name of-chaos-and-order-verify \
		acbilson/of-chaos-and-order:latest \
		hugo \
		--source /app/site \
		--config /etc/hugo/config.toml \
		--destination /tmp/of-chaos-and-order-build

deploy-check:
	cd deploy && ansible-playbook --syntax-check playbooks/site.yml

start:
	podman run -it --rm \
		-p 6300:6300 \
		--name of-chaos-and-order \
		acbilson/of-chaos-and-order:latest
