# ── Base: Official Odoo 17 ─────────────────────────────────────────────────
FROM odoo:17.0

# ── Build arguments injected by Jenkins ────────────────────────────────────
ARG APP_VERSION=v0
ARG BUILD_NUMBER=0
ARG GIT_COMMIT=unknown

# ── Environment variables ──────────────────────────────────────────────────
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_NUMBER=${BUILD_NUMBER}
ENV GIT_COMMIT=${GIT_COMMIT}

# ── OCI image labels ───────────────────────────────────────────────────────
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL build.number="${BUILD_NUMBER}"
LABEL maintainer="your-team@example.com"

# ── Copy config ────────────────────────────────────────────────────────────
COPY docker/odoo.conf /etc/odoo/odoo.conf

# ── FIX: write version file safely ─────────────────────────────────────────
USER root

RUN mkdir -p /var/lib/odoo && \
    echo "{\"version\":\"${APP_VERSION}\",\"build\":\"${BUILD_NUMBER}\",\"commit\":\"${GIT_COMMIT}\"}" \
    > /var/lib/odoo/version.json && \
    chown -R odoo:odoo /var/lib/odoo

USER odoo

# ── Ports ──────────────────────────────────────────────────────────────────
EXPOSE 8069 8071 8072

# ── Start Odoo ─────────────────────────────────────────────────────────────
CMD ["/usr/bin/odoo", "--config=/etc/odoo/odoo.conf"]
