# Changelog

## 2026-11-23: Homer v26.11.4 (first release)

- Homer `b4bz/homer:v26.11.4@sha256:92032ac8bcb812283bfe93750d0fe6ce52a6010699a0de46fdcbf2164e56a970`.
- Basic auth from `HOMER_USERNAME` / `HOMER_PASSWORD` (generated), `/healthz` open for Railway's health check.
- Volume at `/www/assets` with Homer's default assets and a starter `config.yml` on the first boot.
- Optional `HOMER_CONFIG_YML` writes `config.yml` on every start.
- Wrapper exits non-zero if lighttpd stops unexpectedly, so Railway's `ON_FAILURE` policy restarts it.
