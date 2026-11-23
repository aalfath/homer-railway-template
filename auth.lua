-- HTTP basic auth for Homer, run by lighttpd's built-in mod_magnet
-- (the lighttpd package in the upstream image ships without mod_auth).
-- Off when HOMER_PASSWORD is empty. /healthz stays open for Railway's health check.
local pass = os.getenv("HOMER_PASSWORD") or ""
if pass == "" then return 0 end
local r = lighty.r
if r.req_attr["uri.path"] == "/healthz" then return 0 end
local expected = (os.getenv("HOMER_USERNAME") or "admin") .. ":" .. pass
local h = r.req_header["Authorization"]
if h then
  local b = h:match("^[Bb]asic%s+(%S+)%s*$")
  if b then
    local cred = lighty.c.b64dec(b)
    if cred and lighty.c.secret_eq(cred, expected) then return 0 end
  end
end
r.resp_header["WWW-Authenticate"] = 'Basic realm="Homer", charset="UTF-8"'
r.resp_header["Cache-Control"] = "no-store"
r.resp_body.set({ "Login required\n" })
return 401
