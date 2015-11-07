local PLUGIN = {}

PLUGIN.Title = "TTT Scoreboard Override"
PLUGIN.Description = "Overrides the TTT scoreboard so that it displays Evolve's rank colours."
PLUGIN.Author = "Ziks"

function PLUGIN:PostGamemodeLoaded()
	local original = GAMEMODE.TTTScoreboardColorForPlayer
	function GAMEMODE:TTTScoreboardColorForPlayer(ply)
		if IsValid(ply) and evolve and evolve.ranks and evolve.ranks[ply:EV_GetRank()] then
			return evolve.ranks[ply:EV_GetRank()].Color
		end
		
		return original(GAMEMODE, ply)
	end
end

evolve:RegisterPlugin(PLUGIN)
