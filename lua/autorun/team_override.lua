
if SERVER then return end

local playerColor = Color(140, 160, 225)
team.SetUp(1, "Players", playerColor)
team.SetUp(1001, "Unassigned", playerColor)
team.SetUp(2, "Administrators", Color(100, 101, 255))
team.SetUp(3, "Owners", Color(110, 195, 134))

local PLAYER = FindMetaTable("Player")

PLAYER.RealTeam = PLAYER.RealTeam or PLAYER.Team
function PLAYER:Team()
	if self:RealTeam() == 1001 then
		if self:IsSuperAdmin() then
			return 3
		elseif self:IsAdmin() then
			return 2
		else
			return 1
		end
	end
	return self:RealTeam()
end

