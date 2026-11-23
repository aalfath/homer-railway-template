# Homer, the official image pinned by version and digest.
# Bump both the tag and the digest together, and add a CHANGELOG.md entry.
FROM b4bz/homer:v26.11.4@sha256:92032ac8bcb812283bfe93750d0fe6ce52a6010699a0de46fdcbf2164e56a970

# The wrapper starts as root only to make the Railway volume (mounted root-owned)
# writable for the lighttpd user; lighttpd itself drops to that user.
USER root

COPY lighttpd-railway.conf /lighttpd-railway.conf
COPY start.sh /railway-start.sh
COPY config.yml /www/railway-default-config.yml

RUN chmod 0755 /railway-start.sh \
 && printf 'ok\n' > /www/healthz \
 && chown 1000:1000 /www/healthz /www/railway-default-config.yml

ENV PORT=8080

HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose -Y off --tries=1 --spider http://127.0.0.1:${PORT}/healthz || exit 1

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "/railway-start.sh"]
