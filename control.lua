debug = false

local acceptedTypes = {
	car = true,
	locomotive = true,
}
local filterCache = {}
local sPickupKey = "folk-justgo-pickup"
local pickup = setmetatable({}, {
    __index = function(self, id)
		local v = settings.get_player_settings(game.players[id])[sPickupKey].value
		rawset(self, id, v)
		return v
	end
})

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if not event or not event.setting then return end
	if event.setting == sPickupKey then
		pickup[event.player_index] = nil
	end
end)

local function onBuildEntity(event)
	local e = event.created_entity
	if not e or not e.valid or not acceptedTypes[e.type] then return end
	local player = game.players[event.player_index]
	if player.driving or (player.vehicle ~= nil and player.vehicle.valid) then return end
	if not player.can_reach_entity(e) then return end

  -- For special cases where the item and entity name are not equal
  -- Hovercrafts mod
  local iemap = {}
  iemap["hcraft-item"] = "hcraft-entity"
  iemap["mcraft-item"] = "mcraft-entity"

	local playerIndex = event.player_index
	if not filterCache[playerIndex] then filterCache[playerIndex] = {} end
	if filterCache[playerIndex] and filterCache[playerIndex][e.name] then
		local f = player.get_quick_bar_slot(filterCache[playerIndex][e.name])
		if (f) and type(f.name) == "string" and ( f.name == e.name or iemap[f.name] == e.name ) then
			if not global.ent then global.ent = {} end
			player.teleport(e.position)
			player.driving = true
			global.ent[player.index] = e
			return -- We are done, just go!
		else
			filterCache[playerIndex][e.name] = nil
		end
	end

	for i = 1, 100 do
		local f = player.get_quick_bar_slot(i)
    if (f) and type(f.name) == "string" and ( f.name == e.name or iemap[f.name] == e.name ) then
			if not global.ent then global.ent = {} end
			filterCache[playerIndex][e.name] = i
			player.teleport(e.position)
			player.driving = true
			global.ent[player.index] = e
			return -- We are done, just go!
		end
	end
end
script.on_event(defines.events.on_built_entity, onBuildEntity)


local function driving(event)
	if not global.ent or not global.ent[event.player_index] then return end
	local player = game.players[event.player_index]
	if not player or not player.valid or player.driving or player.vehicle then return end
	if not pickup[event.player_index] then return end

	if global.ent[player.index].valid and global.ent[player.index].minable then
		player.mine_entity(global.ent[player.index])
	end
	global.ent[player.index] = nil
end
script.on_event(defines.events.on_player_driving_changed_state, driving)

-- Debug helper, prints anything to console for all players
function printAll(text, bool)
	if (debug or bool) then
		local text2 = ""
		if type(text) == "table" then text2 = serpent.block(text, {comment=false})
			for i in pairs (game.players) do
				game.players[i].print(text2)
			end
		else
			for i in pairs (game.players) do
				game.players[i].print(text)
			end
		end
	end
end
