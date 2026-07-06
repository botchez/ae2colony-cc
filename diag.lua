-- AE2 Colony diagnostic: dump what the colony_integrator actually sees.
local colony = peripheral.find("colony_integrator")
if not colony then
  printError("No colony_integrator peripheral found. Check it's attached/wired to this computer.")
  return
end

print("== Colony integrator ==")
local function try(label, fn)
  local ok, res = pcall(fn)
  if ok then
    print(label .. ": " .. tostring(res))
  else
    print(label .. ": <error> " .. tostring(res))
  end
end

try("isInColony", function() return colony.isInColony() end)
try("colonyName", function() return colony.getColonyName() end)
try("colonyID",   function() return colony.getColonyID() end)

print("== getRequests() ==")
local ok, reqs = pcall(function() return colony.getRequests() end)
if not ok then
  printError("getRequests() threw: " .. tostring(reqs))
  return
end

local n = 0
for _ in pairs(reqs) do n = n + 1 end
print("request count: " .. n)

for i, r in ipairs(reqs) do
  local item = r.items and r.items[1]
  print(string.format("[%d] target=%s  name=%s  count=%s  item=%s",
    i,
    tostring(r.target),
    tostring(r.name),
    tostring(r.count),
    tostring(item and item.name)))
end

if n == 0 then
  print("")
  print("No open requests. In MineColonies this usually means:")
  print(" - the builder hut has no builder hired, or")
  print(" - the builder isn't actively building yet, or")
  print(" - the builder already has everything it needs.")
end
