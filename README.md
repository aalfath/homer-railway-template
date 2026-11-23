[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/homer-2?utm_medium=integration&utm_source=button&utm_campaign=homer)

# Homer on Railway

One-click Railway template for [Homer](https://github.com/homer-dashboard/homer) (Apache-2.0): a simple static homepage for your servers and services, configured with one YAML file.

## What it deploys

One service, **Homer**, built from this repo's `Dockerfile`:

- the official image `b4bz/homer:v26.11.4`, pinned by digest (`sha256:92032ac8bcb812283bfe93750d0fe6ce52a6010699a0de46fdcbf2164e56a970`);
- lighttpd (from the upstream image) serving Homer on `PORT`, behind HTTP basic auth, so your list of services isn't public;
- a volume at `/www/assets` for `config.yml`, icons, themes and custom CSS. On the first boot it gets Homer's default assets and a starter `config.yml`; after that the wrapper never overwrites anything on it (unless you set `HOMER_CONFIG_YML`, below);
- health check `GET /healthz` (open without a login), restart policy `ON_FAILURE`. If lighttpd stops on its own, the wrapper exits non-zero so Railway restarts it.

It needs about 2 MB of RAM and fits Railway's Free plan (0.5 GB) with room to spare.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `HOMER_PASSWORD` | `${{secret(24)}}` | Basic-auth password, generated at deploy. Find it in the service's **Variables** tab. Set it to an empty value to make the dashboard public. |
| `HOMER_USERNAME` | `admin` | Basic-auth user name. |
| `PORT` | `8080` | Port lighttpd listens on (the public domain points to it). |

Optional, not in the template: `HOMER_CONFIG_YML`. Put the whole contents of your `config.yml` in it and redeploy: the wrapper writes it to the volume on every start, replacing the file there. Leave it unset if you'd rather edit `/www/assets/config.yml` on the volume (for example with `railway ssh`). All options are in Homer's [configuration docs](https://github.com/homer-dashboard/homer/blob/main/docs/configuration.md).

## After deploy

1. Open the service's public URL and log in with `admin` and the `HOMER_PASSWORD` value from the **Variables** tab.
2. You see the starter dashboard. Replace it with your own `config.yml` (see `HOMER_CONFIG_YML` above). Your own icons go in `/www/assets` on the volume (reference them as `assets/<file>`), or use Font Awesome icons and image URLs.
3. Smart cards (Proxmox, Portainer, Uptime Kuma and more) call those apps' APIs from the visitor's browser, so the apps must be reachable from where you open Homer and allow CORS. See [custom services](https://github.com/homer-dashboard/homer/blob/main/docs/customservices.md).

## Updates

The `Dockerfile` pins Homer by version and digest. When a new Homer release comes out we bump the pin here and add an entry to [CHANGELOG.md](CHANGELOG.md). Railway then shows an "update available" notice on projects deployed from this template, and you choose when to apply it. Your volume (config and assets) is kept across updates.

## Files

- `Dockerfile`: the pinned upstream image plus the wrapper.
- `start.sh`: volume ownership, first-boot assets and starter config, `HOMER_CONFIG_YML`, then lighttpd in the foreground.
- `lighttpd-railway.conf`: the upstream lighttpd config plus basic auth.
- `auth.lua`: the basic-auth check (lighttpd `mod_magnet`; the upstream lighttpd has no `mod_auth`).
- `config.yml`: the starter dashboard copied to the volume on the first boot.
