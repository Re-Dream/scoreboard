
if SERVER then
	AddCSLuaFile("scoreboard/scoreboard.lua")
	AddCSLuaFile("scoreboard/team_panel.lua")
	AddCSLuaFile("scoreboard/player_panel.lua")
	AddCSLuaFile("scoreboard/connecting_team.lua")
	include("scoreboard/connecting_team.lua")
else
	include("scoreboard/scoreboard.lua")
end

