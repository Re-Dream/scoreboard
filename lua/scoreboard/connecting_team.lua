
local tag = "connecting_team"

if SERVER then
	util.AddNetworkString(tag)

	gameevent.Listen("player_connect")
	hook.Add("player_connect", tag, function(data)
		local info = {}
		info.name = data.name
		info.steamid = data.networkid
		info.userid = data.userid
		info.left = false

		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect", tag, function(data)
		local info = {}
		info.name = data.name
		info.steamid = data.networkid
		info.userid  = data.userid
		info.left = true

		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end)
elseif CLIENT then
	scoreboard.ConnectingTeam = -1
	scoreboard.DisconnectedTeam = -2
	scoreboard.DisconnectedTimeout = 30

	team.SetUp(scoreboard.ConnectingTeam, "Connecting to server...", Color(97, 184, 12))
	team.SetUp(scoreboard.DisconnectedTeam, "Recently disconnected", Color(63, 67, 82))

	scoreboard.Connecting = {}

	net.Receive(tag, function()
		local info = net.ReadTable()
		info.since = CurTime()
		scoreboard.Connecting[info.userid] = info
	end)

	gameevent.Listen("player_spawn")
	hook.Add("player_spawn", tag, function(data)
		local info = scoreboard.Connecting[data.userid]
		if info then
			info.spawned = true
		end
	end)
end

