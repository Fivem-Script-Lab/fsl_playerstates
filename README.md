# Player States
Script designed for easy management of player statistics and other data

### Dependencies
- [DatabaseManager](https://github.com/Fivem-Script-Lab/DatabaseManager)

[Discord Support Server](https://discord.gg/XFgWTCxuvr)

## Documentation

Example code.

```lua

--fxmanifest.lua
lua54 'yes'

server_scripts {
  '@fsl_playerstates/server/init.lua',
  --...
}

--server.lua
CreateState("miner_data", {
  experience = 0
})
local MiningState = GetState("miner_data")

-- some code
local source = 1
local miner_player_state = MiningState(source) -- assuming a no previous state has been created for that player
--miner_player_state.__save_instant = false -- at default, any change is directly set to be saved to DB the moment the value changes
print(miner_player_state.experience) -- 0, again assuming that this is the first time a record has been created
miner_player_state.experience += 5
print(miner_player_state.experience) -- 5
miner_player_state.other_data = "Some Data"
print(miner_player_state.other_data) -- nil, only the fields set in CreateState are present.

```
