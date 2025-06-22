
local ProfileService = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProfileStore"))
local Players = game:GetService("Players")

-->Template profile containing all values we want to save for new players
local ProfileTemplate = {
	Cash = 0,
	Items = {}, --{0,1,2,3}
}

-->Any profile with the "PlayerData" store will have the ProfileTemplate Values
local ProfileStore = ProfileService.New(
	'PlayerData_V_001', --If we change this it changes every data
	ProfileTemplate
) 

-->Store all active profiles of plrs in game
local Profiles: {[player]: typeof(ProfileStore:StartSessionAsync())} = {}

local function PlayerAdded(plr: Player)	
	local profile = ProfileStore:StartSessionAsync(`{plr.UserId}`, {
		Cancel = function()
			return plr.Parent ~= Players
		end,
	})
	
	
	if not profile then warn("No profile")  return end
	
	Profiles[plr] = profile

	local leaderstats = Instance.new("Folder", plr)
	leaderstats.Name = 'leaderstats'

	local Cash = Instance.new('IntValue', leaderstats) 
	Cash.Name = 'Cash'
	Cash.Value = profile.Data.Cash or 0 --Loads the data from the Profile if player is new and has not played it set's it to 0
	
	Cash:GetPropertyChangedSignal("Value"):Connect(function()
		profile.Data.Cash = Cash.Value
	end)
	
	
	if profile ~= nil then


		profile:AddUserId(plr.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			Profiles[plr] = nil
			plr:Kick(`Profile session end - Please rejoin`)
		end)


		if  plr.Parent ~= Players then profile:EndSession() end
			Profiles[plr] = profile
		    print(`Profile loaded for {plr.DisplayName}!`)
		  
			-- EXAMPLE: Grant the player 100 coins for joining:
			profile.Data.Cash += 100
			-- You should set "Cash" in PROFILE_TEMPLATE and use "Profile:Reconcile()",
			-- otherwise you'll have to check whether "Data.Cash" is not nil

	else
		-- This condition should only happen when the Roblox server is shutting down
		plr:Kick(`Profile load fail - Please rejoin`)
	end
	game.ReplicatedStorage:WaitForChild("CreatePlot"):Fire(plr, profile.Data.Items)
end



-- In case Players have joined the server earlier than this script ran:
for _, player in game.Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)


--When player leaves game
game.Players.PlayerRemoving:Connect(function(player: Player) 
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end)


--Listens for when the ItemUnlocked event is fired
script:WaitForChild('ItemUnlocked').Event:Connect(function(plr, ItemId)
	local profile = Profiles[plr]
	table.insert(profile.Data.Items, ItemId) --Adds the Id of the Item to the Profile Template Data
end)
