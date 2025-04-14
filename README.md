# Caddy WAF OVH

A Caddy server image supercharged with the OVH & Coraza WAF plugins with tracing enabled.

## Usage

Complex example leveraging :

* Wildcard domain names auto HTTPS via the [OVH plugin](https://github.com/caddy-dns/ovh).
* Protected by [Coraza](https://github.com/corazawaf/coraza-caddy) with OWASP Core Ruleset.
* With tracing via [OpenTelemetry enabled](https://caddyserver.com/docs/caddyfile/directives/tracing#configuration)

*docker-compose.yaml*
```yaml
configs:
  caddyfile:
    # Caddyfile env substition (not the Docker Compose one !)
    content: |
        {
          order coraza_waf first
        }
        (waf) {
            coraza_waf {
                load_owasp_crs
                directives `
                Include @coraza.conf-recommended
                Include @crs-setup.conf.example
                Include @owasp_crs/*.conf
                SecRuleEngine On
                `
            }
        }
        *.{$ROOT_DOMAIN} {
          tls {
            dns ovh {
                  # https://www.ovh.com/auth/api/createToken
                  endpoint ovh-eu
                  application_key {$OVH_APPLICATION_KEY}
                  application_secret {$OVH_APPLICATION_SECRET}
                  consumer_key {$OVH_CONSUMER_KEY}
              }
          }
          import waf
          tracing {
        	  span proxy_request
          }
          encode zstd gzip
          reverse_proxy http://app
        }

services:
    caddy:
      image: ghcr.io/gabzz01/caddy-waf-ovh/caddy
      restart: unless-stopped
      configs:
        - source: caddyfile
          target: /etc/caddy/Caddyfile
      environment:
        ROOT_DOMAIN: localhost
        OVH_APPLICATION_KEY: "${OVH_APPLICATION_KEY:?Error: OVH_APPLICATION_KEY is not set}"
        OVH_APPLICATION_SECRET: "${OVH_APPLICATION_SECRET:?Error: OVH_APPLIOVH_APPLICATION_SECRETCATION_KEY is not set}"
        OVH_CONSUMER_KEY:  "${OVH_CONSUMER_KEY:?Error: OVH_CONSUMER_KEY is not set}"
        OTEL_EXPORTER_OTLP_HEADERS: "myAuthHeader=myToken"
        OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: http://tracing:4317
      ports:
        - "80:80"
        - "443:443"
        - "443:443/udp"
      networks:
        - app-tier
      volumes:
        - caddy_data:/data
        - caddy_cfg:/config

    # =============== Placeholder services ===============
    app:
      image: nginx:latest
      restart: unless-stopped
      networks:
        - app-tier
    tracing:
      image: jaegertracing/jaeger:2.5.0
      networks:
        - app-tier

volumes:
  caddy_data:
  caddy_cfg:

networks:
  app-tier:
    driver: bridge
    name: my-app
```