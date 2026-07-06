-- AE2 Colony launcher. Does NOT hit the network, so reboots are free and
-- won't trip GitHub's rate limit. To pull the latest version, run: update
if not fs.exists("ae2Colony.lua") then
  printError("ae2Colony.lua not found. Run 'update' first to download it.")
  return
end
shell.run("ae2Colony.lua")
