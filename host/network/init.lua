-- Unii network adapter. See README.md for the Lua interface the supervisor
-- should call, and for how outcomes map onto effect commands.

local client = require("host.network.client")
local curl = require("host.network.curl_ffi")
local sse = require("host.network.sse")
local json = require("host.network.json")
local redact = require("host.network.redact")

return {
  IS_MOCK = false,
  client = client.new,
  sse = sse,
  json = json,
  redact = redact,
  outcome = client.OUTCOME,
  reason = client.REASON,
  MAX_SUMMARY_INFLIGHT = client.MAX_SUMMARY_INFLIGHT,
  MAX_TURN_INFLIGHT = client.MAX_TURN_INFLIGHT,
  DEFAULT_MAX_INFLIGHT = client.DEFAULT_MAX_INFLIGHT,
  DEFAULT_TIMEOUT_MS = client.DEFAULT_TIMEOUT_MS,
  DEFAULT_CONNECT_TIMEOUT_MS = client.DEFAULT_CONNECT_TIMEOUT_MS,
  DEFAULT_MAX_BODY = client.DEFAULT_MAX_BODY,
  curl_version = function()
    return curl.version()
  end,
}
