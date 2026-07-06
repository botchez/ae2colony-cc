-- AE2 Colony diagnostic: dump what the colony_integrator sees, print it,
-- and upload it to a paste service so it can be shared as a single URL.
local out = {}
local function say(line)
  line = line == nil and "" or tostring(line)
  print(line)
  out[#out + 1] = line
end

local colony = peripheral.find("colony_integrator")
if not colony then
  say("No colony_integrator peripheral found. Check it's attached/wired to this computer.")
else
  local function try(label, fn)
    local ok, res = pcall(fn)
    if ok then say(label .. ": " .. tostring(res))
    else say(label .. ": <error> " .. tostring(res)) end
  end

  say("== Colony integrator ==")
  try("isInColony", function() return colony.isInColony() end)
  try("colonyName", function() return colony.getColonyName() end)
  try("colonyID",   function() return colony.getColonyID() end)

  say("== getRequests() ==")
  local ok, reqs = pcall(function() return colony.getRequests() end)
  if not ok then
    say("getRequests() threw: " .. tostring(reqs))
  else
    local n = 0
    for _ in pairs(reqs) do n = n + 1 end
    say("request count: " .. n)
    for i, r in ipairs(reqs) do
      local item = r.items and r.items[1]
      say(string.format("[%d] target=%s  name=%s  count=%s  item=%s",
        i, tostring(r.target), tostring(r.name), tostring(r.count),
        tostring(item and item.name)))
    end
    if n == 0 then
      say("")
      say("No open requests. In MineColonies this usually means the builder")
      say("hut has no builder hired, the builder isn't actively building yet,")
      say("or the builder already has everything it needs.")
    end
  end
end

-- Upload the collected output to dpaste so it can be shared as one URL.
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
  print("Upload failed (HTTP blocked or host not allowed).")
  print("You can read the output above instead.")
end
