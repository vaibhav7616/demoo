# ── Base: Official Odoo 17 ─────────────────────────────────────────────────
FROM odoo:17.0

# ── Build arguments injected by Jenkins ────────────────────────────────────
ARG APP_VERSION=v0
ARG BUILD_NUMBER=0
ARG GIT_COMMIT=unknown

# ── Expose version as environment variables ─────────────────────────────────
# These are readable inside the running container:
#   kubectl exec <pod> -- printenv APP_VERSION
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_NUMBER=${BUILD_NUMBER}
ENV GIT_COMMIT=${GIT_COMMIT}

# ── OCI image labels (visible via: docker inspect <image>) ─────────────────
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL build.number="${BUILD_NUMBER}"
LABEL maintainer="your-team@example.com"

# ── Copy custom Odoo addons (if any) ───────────────────────────────────────
# COPY ./addons /mnt/extra-addons

# ── Copy odoo.conf ─────────────────────────────────────────────────────────
COPY docker/odoo.conf /etc/odoo/odoo.conf

# ── Create a tiny version-info endpoint ────────────────────────────────────
# Odoo serves static files from /usr/lib/python3/dist-packages/odoo/addons/web/static
# We write a small JSON file that can be fetched for health-check version probing.
USER root
RUN echo "{\"version\":\"${APP_VERSION}\",\"build\":\"${BUILD_NUMBER}\",\"commit\":\"${GIT_COMMIT}\"}" \
        > /usr/lib/python3/dist-packages/odoo/addons/web/static/version.json
USER odoo

EXPOSE 8069 8071 8072

# Use the official entrypoint (handles DB init, migrations, etc.)
# If environment variables HOST, USER, PASSWORD are set, they will be used.
CMD ["odoo"]
