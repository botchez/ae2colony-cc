-- AE2 Colony diagnostic: dump colony requests, cross-check each against the
-- ME system, print it, and upload to a paste service as a single URL.
local out = {}
local function say(line)
  line = line == nil and "" or tostring(line)
  print(line)
  out[#out + 1] = line
end

local colony = peripheral.find("colony_integrator")
local bridge = peripheral.find("me_bridge")

if not colony then say("No colony_integrator peripheral found.") end
if not bridge then say("No me_bridge peripheral found.") end

if colony then
  say("== Colony ==")
  local function try(label, fn)
    local ok, res = pcall(fn)
    say(label .. ": " .. (ok and tostring(res) or ("<error> " .. tostring(res))))
  end
  try("colonyName", function() return colony.getColonyName() end)
  try("colonyID",   function() return colony.getColonyID() end)
end

-- Build a fingerprint -> stock-count index of the ME system.
local meIndex = {}
if bridge then
  local ok, items = pcall(function() return bridge.getItems() end)
  if ok and items then
    for i = 1, #items do
      local it = items[i]
      if it.fingerprint then meIndex[it.fingerprint] = it end
    end
    say("ME system item types: " .. #items)
  else
    say("bridge.getItems() failed: " .. tostring(items))
  end
end

if colony then
  say("== Requests vs ME stock ==")
  local ok, reqs = pcall(function() return colony.getRequests() end)
  if ok and reqs then
    for i, r in ipairs(reqs) do
      local item = r.items and r.items[1]
      local fp = item and item.fingerprint
      local inMe = fp and meIndex[fp]
      local status
      if not fp then
        status = "NO FINGERPRINT"
      elseif inMe then
        status = string.format("IN ME (stock %d) -> will export", inMe.count)
      else
        status = "NOT in ME -> needs autocraft pattern or manual"
      end
      say(string.format("[%d] x%s %s | %s",
        i, tostring(r.count), tostring(item and item.name), status))
    end
  else
    say("getRequests() failed: " .. tostring(reqs))
  end
end

-- Upload collected output as a single shareable URL.
print("")
print("Uploading output...")
local data = table.concat(out, "\n")
local body = "content=" .. textutils.urlEncode(data) .. "&syntax=text&expiry_days=7"
local ok, resp = pcall(function()
  return http.post("https://dpaste.com/api/v2/", body,
    { ["Content-Type"] = "application/x-www-form-urlencoded" })
end)
if ok and resp then
  local url = (resp.readAll() or ""):gsub("%s+$", "")
  resp.close()
  print("Uploaded. Share this link:")
  print("  " .. url .. ".txt")
else
  print("Upload failed (HTTP blocked). Read the output above instead.")
end
