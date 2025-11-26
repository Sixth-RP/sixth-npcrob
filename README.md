Create a folder called npc_robbery in your server's resources folder
Add the fxmanifest.lua
Add the client.lua from the previous artifact
Add to your server.cfg: ensure npc_robbery
Restart your server


robberyKey - Change the key (default: E)
robberyDistance - How close you need to be
minMoney/maxMoney - Money range
successChance - Probability of success
policeAlertChance - Chance to alert police
robberyTime - How long the robbery takes

Features:

✅ Anti-cheat validation (prevents players from adding invalid amounts)
✅ Money handling for each framework
✅ Police alert system (sends alerts only to on-duty police)
✅ Console logging
✅ Admin commands: /robberylog and /clearrobberylog
