-- Pull the latest AE2 Colony script from the Gist. Run this only when the
-- script has actually changed, to stay under GitHub's rate limit.
local url = "https://raw.githubusercontent.com/botchez/ae2colony-cc/main/colony.lua"
local target = "ae2Colony.lua"

print("Fetching latest " .. target .. " ...")
if fs.exists(target) then fs.delete(target) end

local ok = shell.run("wget", url, target)
if ok and fs.exists(target) then
  print("Updated. Type 'startup' to run, or reboot.")
else
  printError("Download failed. GitHub may be rate-limiting - wait a minute and retry.")
end
