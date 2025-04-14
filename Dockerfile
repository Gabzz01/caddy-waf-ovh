FROM caddy:2-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/ovh \
    --with github.com/corazawaf/coraza-caddy/v2

FROM caddy:2-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy