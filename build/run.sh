#!/bin/sh
echo "running Hugo development server with drafts and future posts..."
    /usr/bin/hugo server \
    --bind=0.0.0.0 \
    --config /etc/hugo/config.toml \
    --contentDir /app/hugo/content \
    --themesDir /app/hugo/themes \
    --cleanDestinationDir \
    --templateMetrics
