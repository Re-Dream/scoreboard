
local tag = "ReDreamScoreboard"

surface.CreateFont(tag .. "Player", {
	font = "Roboto Medium",
	size = 20,
	antialias = true,
})

local Player = {}
Player.Icons = {}

local avatars = {}
local hovered
local function GetAvatar(sid)
	if not avatars[sid] then
		local a = vgui.Create("AvatarImage", vgui.GetWorldPanel())
		a.Avatar = true
		a:SetSteamID(sid, 184)
		a:SetSize(184, 184)
		a:ParentToHUD()
		a.Alpha = 0
		a:SetAlpha(a.Alpha)
		function a:Think()
			self.Alpha = math.Clamp(self.Alpha + (FrameTime() * 2000) * (self.Hide and -1 or 1), 0, 255)
			self:SetAlpha(self.Alpha)
			if not IsValid(hovered) then
				self.Hide = true
			end
		end
		avatars[sid] = a
	end
	return avatars[sid]
end

hook.Add("PostRenderVGUI", tag .. "Player", function()
	if IsValid(hovered) then
		local sid64 = hovered:SteamID64()
		local avatar = GetAvatar(sid64)
		avatar.Hide = false
		local x, y = hovered:LocalToScreen(0, 0)
		avatar:SetPos(x - avatar:GetWide(), y - avatar:GetTall() * 0.5 + hovered:GetTall() * 0.5)
		avatar:SetPaintedManually(true)
		avatar:PaintManual()
		avatar:SetPaintedManually(false)
	end
	hovered = nil
end)

function Player:SteamID64()
	local ply = self.Player
	if not IsValid(ply) and not istable(ply) then return end
	return ply.SteamID64 and ply:SteamID64() or util.SteamIDTo64(ply.steamid)
end

function Player:Init()
	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:Dock(LEFT)

	self.Avatar.Click = vgui.Create("DButton", self.Avatar)
	self.Avatar.Click:Dock(FILL)
	function self.Avatar.Click.Paint(s, w, h)
		if s:IsHovered() then
			hovered = self
		end

		return true
	end
	function self.Avatar.Click.DoClick()
		local sid64 = self:SteamID64()
		if not sid64 then return end

		gui.OpenURL("https://steamcommunity.com/profiles/" .. sid64)
	end
	function self.Avatar.Click.DoRightClick()
		local menu = DermaMenu()
		local ply = self.Player
		local sid64 = self:SteamID64()

		menu:AddOption("Open Profile", function()
			gui.OpenURL("https://steamcommunity.com/profiles/" .. sid64)
		end):SetIcon("icon16/book_go.png")
		menu:AddOption("Copy Profile URL", function()
			SetClipboardText("http://steamcommunity.com/profiles/" .. sid64)
		end):SetIcon("icon16/book_link.png")

		menu:AddSpacer()

		menu:AddOption("Copy SteamID", function()
			SetClipboardText(ply.SteamID and ply:SteamID() or ply.steamid)
		end):SetIcon("icon16/tag_blue.png")
		menu:AddOption("Copy Community ID", function()
			SetClipboardText(tostring(sid64))
		end):SetIcon("icon16/tag_yellow.png")

		menu:Open()
	end

	self.Info = vgui.Create("DButton", self)
	self.Info:Dock(FILL)
	self.Info:SetCursor("arrow")
	function self.Info.DoDoubleClick()
		local ply = self.Player
		if not IsValid(ply) then return end
		if mingeban and mingeban.GetCommand("go") then
			LocalPlayer():ConCommand("mingeban go _" .. ply:EntIndex())
		end
	end
	function self.Info.DoRightClick()
		local menu = DermaMenu()
		local lply = LocalPlayer()
		local ply = self.Player
		if mingeban and mingeban.commands then
			local cmds = mingeban.commands
			if IsValid(ply) and lply ~= ply then
				if lply:HasPermission("command.go") and mingeban.GetCommand("go") then
					menu:AddOption("Go To", function()
						lply:ConCommand("mingeban go _" .. ply:EntIndex())
					end):SetIcon("icon16/bullet_go.png")
				end

				if lply:HasPermission("command.bring") and mingeban.GetCommand("bring") then
					menu:AddOption("Bring", function()
						lply:ConCommand("mingeban bring _" .. ply:EntIndex())
					end):SetIcon("icon16/arrow_in.png")
				end

				menu:AddSpacer()

				if lply:HasPermission("command.kick") and mingeban.GetCommand("kick") then
					menu:AddOption("Kick", function()
						Derma_StringRequest("Scoreboard - Kick " .. ply:Nick(), "What's your reason for kicking this player?", "",
							function(reason)
								if reason:Trim() == "" then
									reason = nil
								end
								RunConsoleCommand("mingeban", "kick", "_" .. ply:EntIndex(), reason)
							end
						)
					end):SetIcon("icon16/door_in.png")
				end

				menu:AddSpacer()

				menu:AddOption("Toggle Mute", function()
					ply:SetMuted(not ply:IsMuted())
				end):SetIcon("icon16/sound_mute.png")
			end
		end
		menu:Open()
	end
	function self.Info.Paint(s, w, h)
		local ply = self.Player
		if not IsValid(ply) and not istable(ply) then
			self.Player = _G.Player(self.UserID)
			if not IsValid(self.Player) then
				self:Remove()
			end
			return true
		end

		local nick = ply.Nick and ply:Nick() or ply.name
		surface.SetFont(tag .. "Player")
		local txt = nick
		local txtW, txtH = surface.GetTextSize(txt)
		surface.SetTextPos(6 + 1, h * 0.5 - txtH * 0.5 + 1)
		surface.SetTextColor(Color(0, 0, 0, 64))
		surface.DrawText(txt)

		surface.SetTextPos(6, h * 0.5 - txtH * 0.5)
		surface.SetTextColor(Color(0, 0, 0, 240))
		surface.DrawText(txt)

		return true
	end
	function self.Info:PaintOver(w, h)
		surface.SetDrawColor(Color(0, 0, 0, 20))
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	if LocalPlayer().AFKTime then
		self.Info.Ping = vgui.Create("DButton", self.Info)
		self.Info.Ping:Dock(RIGHT)
		self.Info.Ping:SetWide(58)
		self.Info.Ping:SetCursor("arrow")
		self.Icons.Clock = Material("icon16/clock.png")
		self.Icons.Latency = Material("icon16/transmit.png")
		self.Icons.Latency2 = Material("icon16/transmit_blue.png")
		function self.Info.Ping.Paint(s, w, h)
			local ply = self.Player
			if IsValid(ply) then
				self.Info.Ping:SetTooltip("Ping / AFK Time")

				local isAFK = ply.IsAFK and ply:IsAFK() or false
				local ping = ply:Ping()

				if isAFK then
					surface.SetDrawColor(Color(127, 64, 255, 70))
				else
					surface.SetDrawColor(Color(127, 167, 99, 70))
				end

				surface.DrawRect(0, 0, w, h)

				local decentPing, badPing = 100, 200
				local pingColor
				local pingIcon = self.Icons.Latency
				if ping <= decentPing then
					pingIcon = self.Icons.Latency2
					pingColor = Color(90, 255, 90)
				elseif ping >= decentPing and ping <= badPing then
					pingColor = Color(255, 255, 90)
				else
					pingColor = Color(255, 90, 90)
				end
				surface.SetMaterial(isAFK and self.Icons.Clock or pingIcon)
				surface.SetDrawColor(isAFK and Color(255, 255, 255) or pingColor)
				surface.DrawTexturedRect(4, h * 0.5 - 8, 16, 16)

				surface.SetFont("DermaDefault")
				local txt
				if isAFK then
					local AFKTime = math.max(0, CurTime() - ply:AFKTime())
					local h = math.floor(AFKTime / 60 / 60)
					local m = math.floor(AFKTime / 60 % 60)
					local s = math.floor(AFKTime % 60)
					txt = string.format("%d:%.2d", h >= 1 and h or m, h >= 1 and m or s)
				else
					txt = ping
				end
				local txtW, txtH = surface.GetTextSize(txt)
				surface.SetTextPos(4 + 16 + 4, h * 0.5 - txtH * 0.5)
				surface.SetTextColor(Color(0, 0, 0, 230))
				surface.DrawText(txt)
			else
				self.Info.Ping:SetTooltip("Connecting since")

				surface.SetDrawColor(Color(127, 167, 99, 70))
				surface.DrawRect(0, 0, w, h)

				surface.SetMaterial(self.Icons.Clock)
				surface.SetDrawColor(Color(255, 255, 255))
				surface.DrawTexturedRect(4, h * 0.5 - 8, 16, 16)

				surface.SetFont("DermaDefault")
				local txt
				if ply.since then
					local since = math.max(0, CurTime() - ply.since or 0)
					local _h = math.floor(since / 60 / 60)
					local _m = math.floor(since / 60 % 60)
					local _s = math.floor(since % 60)
					if ply.left == true and since > player.DisconnectedTimeout then
						player.Connecting[self.UserID] = nil
					end
					txt = string.format("%d:%.2d", _h >= 1 and _h or _m, _h >= 1 and _m or _s)
				else
					txt = "WHAT"
				end
				local txtW, txtH = surface.GetTextSize(txt)
				surface.SetTextPos(4 + 16 + 4, h * 0.5 - txtH * 0.5)
				surface.SetTextColor(Color(0, 0, 0, 230))
				surface.DrawText(txt)
			end

			return true
		end
	end

	if LocalPlayer().GetPlaytime then
		self.Info.Playtime = vgui.Create("DButton", self.Info)
		self.Info.Playtime:Dock(RIGHT)
		self.Info.Playtime:SetWide(46)
		self.Info.Playtime:SetCursor("arrow")
		self.Info.Playtime:SetTooltip("Playtime")
		function self.Info.Playtime.Paint(s, w, h)
			local ply = self.Player
			if not IsValid(ply) then return true end

			surface.SetFont("DermaDefault")
			local playtime = ply:GetPlaytime()
			local _h = math.floor(playtime / 60 / 60)
			local _m = math.floor(playtime / 60 % 60)
			local _s = math.floor(playtime % 60)
			local txt
			if _h < 1 then
				txt = string.format("%d m", _m, _s)
			elseif _h < 10 then
				txt = string.format("%d:%.2d h", _h, _m)
			else
				txt = string.format("%d h", _h, _m)
			end
			local txtW, txtH = surface.GetTextSize(txt)
			surface.SetTextPos(w * 0.5 - txtW * 0.5, h * 0.5 - txtH * 0.5)
			surface.SetTextColor(Color(0, 0, 0, 230))
			surface.DrawText(txt)

			return true
		end
	end
end

function Player:RefreshAvatar()
	local ply = self.Player
	if IsValid(ply) and not ply:SteamID64() then return end
	if not IsValid(ply) and not istable(ply) then return end
	local sid64 = self:SteamID64()

	local w = 32
	if self.Avatar:GetTall() > 32 then w = 64 end
	if self.Avatar:GetTall() > 64 then w = 184 end
	self.Avatar:SetSteamID(sid64, w)
end
function Player:SetPlayer(ply)
	self.Player = ply
	self:RefreshAvatar()
end

function Player:PerformLayout()
	self.Avatar:SetWide(self.Avatar:GetTall())
	self:RefreshAvatar()
end

function Player:Think()
	local ply = self.Player
	if player.Connecting then
		local info = player.Connecting[ply.userid]
		if istable(ply) then
			local ent = _G.Player(ply.userid)
			if IsValid(ent) and info.spawned and ent:Alive() then -- has the player fully spawned
				player.Connecting[ply.userid] = nil
			end
		end
	end

	if self.Info.Playtime then
		self.Info.Playtime:SetVisible(IsValid(ply))
	end
end

Player.Icons.Friend  = Material("icon16/user_green.png")
Player.Icons.Self    = Material("icon16/user.png")
Player.Icons.Shield  = Material("icon16/shield.png")
Player.Icons.Typing  = Material("icon16/comments.png")
Player.Icons.Wrench  = Material("icon16/wrench.png")
Player.Icons.NoClip  = Material("icon16/collision_off.png")
Player.Icons.Vehicle = Material("icon16/car.png")
Player.Icons.Muted   = Material("icon16/sound_mute.png")
for name, mat in next, Player.Icons do
	mat:SetVector("$color", Vector(3, 3, 3)) -- set to white-ish, better control over colors
end

local building = {
	weapon_physgun = true,
	gmod_tool = true,
}
Player.Tags = {
	Admin = function(ply)
		if ply:IsAdmin() then
			return "admin", Player.Icons.Shield, Color(215, 157, 0)
		end
	end,
	Typing = function(ply)
		if ply:IsTyping() then
			return "typing", Player.Icons.Typing, Color(113, 210, 255)
		end
	end,
	Building = function(ply)
		if IsValid(ply:GetActiveWeapon()) and building[ply:GetActiveWeapon():GetClass()] then
			return "building", Player.Icons.Wrench, Color(255, 126, 0)
		end
	end,
	NoClip = function(ply)
		if ply:GetMoveType() == MOVETYPE_NOCLIP and not ply:InVehicle() then
			return "noclip", Player.Icons.NoClip, Color(0, 255, 174)
		end
	end,
	Vehicle = function(ply)
		if ply:InVehicle() then
			return "in vehicle", Player.Icons.Vehicle, Color(183, 85, 220)
		end
	end,
	Member = function(ply)
		if _G.WebMaterial and ply:GetNWBool("is_in_steamgroup") then
			return "member", WebMaterial("redream_logo_16", "https://gmlounge.us/media/redream-16.png")
		end
	end,
	Muted = function(ply)
		if ply:IsMuted() then
			return "muted", Player.Icons.Muted, Color(200, 42, 42)
		end
	end
}
function Player:Paint(w, h)
	local lply = LocalPlayer()
	local ply = self.Player
	local hovered = self.Info:IsHovered() or self.Info:IsChildHovered()

	local isAFK = (IsValid(ply) and ply.IsAFK) and ply:IsAFK() or false

	surface.SetDrawColor(isAFK and Color(207, 211, 221, 190) or Color(244, 248, 255, 190))
	surface.DrawRect(0, 0, w, h)

	if hovered then
		surface.SetDrawColor(Color(255, 255, 255, self.Info.Depressed and 40 or 90))
		surface.DrawRect(0, 0, w, h)
	end

	if not IsValid(ply) then return true end

	local infoW = 0
	for _, pnl in next, self.Info:GetChildren() do
		infoW = infoW + pnl:GetWide()
	end
	local x = w - infoW --- 4
	for _, tag in next, self.Tags do
		local text, icon, color = tag(ply)
		if text and icon then
			if hovered then
				surface.SetFont("DermaDefault")
				local txtW, txtH = surface.GetTextSize(text)
				x = x - txtW
				surface.SetTextColor(Color(0, 0, 0, 192))
				surface.SetTextPos(x, h * 0.5 - txtH * 0.5)
				surface.DrawText(text)
				x = x - 4
			end

			x = x - 16
			local color = color or Color(255, 255, 255)
			color.a = 192
			surface.SetDrawColor(color)
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(x, h * 0.5 - 8, 16, 16)

			x = x - 4
		end
	end

	if (lply ~= ply and ply:GetFriendStatus() == "friend") or lply == ply then
		DisableClipping(true)
			surface.SetDrawColor(Color(255, 255, 255, 192))
			surface.SetMaterial(lply == ply and self.Icons.Self or self.Icons.Friend)
			surface.DrawTexturedRect(-16 - 4, h * 0.5 - 8, 16, 16)
		DisableClipping(false)
	end

	return true
end

vgui.Register(tag .. "Player", Player, "EditablePanel")

