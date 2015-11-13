local PLUGIN = {}

PLUGIN.Title = "Rock the Vote"
PLUGIN.Description = "Rock the vote to change the map!"
PLUGIN.Author = "Metapyziks"
PLUGIN.ChatCommand = "rtv"
PLUGIN.Privileges = { "Rock the Vote" }

function PLUGIN:Call( ply, args )
    RTV.StartVote( ply )
end

evolve:RegisterPlugin( PLUGIN )
