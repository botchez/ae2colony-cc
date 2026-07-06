-- AE2 Colony diagnostic: dump the FULL build material list for every active
-- work order (not just currently-open requests), with ME stock alongside,
-- then upload to a paste service as a single URL.
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
  local function try(label, fn)
    local ok, res = pcall(fn)
    say(label .. ": " .. (ok and tostring(res) or ("<error> " .. tostring(res))))
  end
  say("== Colony ==")
  try("name", function() return colony.getColonyName() end)
  try("id",   function() return colony.getColonyID() end)
end

-- ME stock summed by registry name.
local meByName = {}
if bridge then
  local ok, items = pcall(function() return bridge.getItems() end)
  if ok and items then
    for i = 1, #items do
      local it = items[i]
      if it.name then meByName[it.name] = (meByName[it.name] or 0) + (it.count or 0) end
    end
    say("ME item types: " .. #items)
  else
    say("bridge.getItems() failed: " .. tostring(items))
  end
end

if colony then
  say("== Work orders: full build materials ==")
  local ok, orders = pcall(function() return colony.getWorkOrders() end)
  if not ok then
    say("getWorkOrders() failed: " .. tostring(orders))
  elseif not orders or #orders == 0 then
    say("No active work orders. (Nothing is being built right now.)")
  else
    for _, wo in ipairs(orders) do
      say(string.format("-- Work Order #%s: %s (type=%s level=%s claimed=%s)",
        tostring(wo.id), tostring(wo.buildingName or wo.type),
        tostring(wo.workOrderType), tostring(wo.targetLevel), tostring(wo.isClaimed)))
      local rok, res = pcall(function() return colony.getWorkOrderResources(wo.id) end)
      if not rok then
        say("   getWorkOrderResources failed: " .. tostring(res))
      elseif not res or #res == 0 then
        say("   (no resource list returned)")
      else
        for _, r in ipairs(res) do
          local me = meByName[r.item]
          say(string.format("   %s | need=%s avail=%s deliv=%s status=%s | ME=%s",
            tostring(r.displayName or r.item), tostring(r.needed),
            tostring(r.available), tostring(r.delivering), tostring(r.status),
            me and tostring(me) or "0"))
        end
      end
    end
  end

  local qok, reqs = pcall(function() return colony.getRequests() end)
  if qok and reqs then say("== Open requests right now: " .. #reqs .. " ==") end
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
