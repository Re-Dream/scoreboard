
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
	player.ConnectingTeam = -1
	player.DisconnectedTeam = -2
	player.DisconnectedTimeout = 30

	team.SetUp(player.ConnectingTeam, "Connecting to server...", Color(97, 184, 12))
	team.SetUp(player.DisconnectedTeam, "Recently disconnected", Color(63, 67, 82))

	player.Connecting = {}

	net.Receive(tag, function()
		if not player.Connecting then return end
		local info = net.ReadTable()
		info.since = CurTime()
		player.Connecting[info.userid] = info
	end)

	gameevent.Listen("player_spawn")
	hook.Add("player_spawn", tag, function(data)
		if not player.Connecting then return end
		local info = player.Connecting[data.userid]
		if info then
			info.spawned = true
		end
	end)
end

