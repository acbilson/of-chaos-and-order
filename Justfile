set shell := ["/opt/homebrew/bin/fish", "-c"]

## builds a podman image. Options are: hugo, firewithin
build:
	podman build -f build/Dockerfile -t acbilson/of-chaos-and-order:latest .

start:
	podman run -it --rm \
		-p 6300:6300 \
		--name of-chaos-and-order \
		acbilson/of-chaos-and-order:latest

