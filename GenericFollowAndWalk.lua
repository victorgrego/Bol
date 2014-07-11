local version = "1.11"
--[[
    Passive Follow by VictorGrego.
]]
finishedOnLoad = false
initiated = false

--UPDATE SETTINGS
local AutoUpdate = true
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/victorgrego/BolSorakaScripts/master/GenericFollowAndWalk.lua?"..math.random(100)
local UPDATE_TMP_FILE = LIB_PATH.."GFWTmp.txt"
local versionmessage = "<font color=\"#81BEF7\" >Changelog: Corrected a bug where soraka would stuck in font/towers</font>"

function Update()
	DownloadFile(URL, UPDATE_TMP_FILE, UpdateCallback)
end

function UpdateCallback()
	file = io.open(UPDATE_TMP_FILE, "rb")
	if file ~= nil then
		content = file:read("*all")
		file:close()
		os.remove(UPDATE_TMP_FILE)
		if content then
			tmp, sstart = string.find(content, "local version = \"")
			if sstart then
				send, tmp = string.find(content, "\"", sstart+1)
			end
			if send then
				Version = tonumber(string.sub(content, sstart+1, send-1))
			end
			if (Version ~= nil) and (Version > tonumber(version)) and content:find("--EOS--") then
				file = io.open(SELF, "w")
			if file then
				file:write(content)
				file:flush()
				file:close()
				PrintChat("<font color=\"#81BEF7\" >GenericFollowAndWalk:</font> <font color=\"#00FF00\">Successfully updated to: v"..Version..". Please reload the script with F9.</font>")
			else
				PrintChat("<font color=\"#81BEF7\" >GenericFollowAndWalk:</font> <font color=\"#FF0000\">Error updating to new version (v"..Version..")</font>")
			end
			elseif (Version ~= nil) and (Version == tonumber(version)) then
				PrintChat("<font color=\"#81BEF7\" >GenericFollowAndWalk:</font> <font color=\"#00FF00\">No updates found, latest version: v"..Version.." </font>")
			end
		end
	end
end

--Classes Area
root = nil
--Task Class
Task = {}
function Task:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function Task:run()
	PrintChat("CHAMOU TASK RUN")
end

function Task:addChild(value)
	table.insert(self,value)
end

function Task:addAll(value)
	for i = 1, #value, 1 do
		table.insert(self, value[i])
	end
end

function Task:printAll()
	for i = 1, #self, 1 do
		PrintChat("Value: "..self[i])
	end
end

-- Selector Class
Selector = Task:new()

function Selector:run()
	for i, v in ipairs(self) do
		if v:run() then return true end
	end
	return false
end

--Sequence Class
Sequence = Task:new()

function Sequence:run()
	for i, v in ipairs(self) do
		if not v:run() then return false end
	end
	return true
end

--Action Class
Action = Task:new()

function Action:run()
	local actions = {}
	--PrintChat(self.action)
	
	actions["startTime"] = function()
		if os.clock() > SCRIPT_START_TIME then return true
		else return false end
	end
	
	actions["noPartner"] = function()
		--if(partner ~= nil) then PrintChat(partner.name) end
		if partner == nil then return true
		else return false
		end
	end
	
	actions["partnerAfk"] = function()
		checkAfk()
		return pAfk
	end
	
	actions["partnerAlive"] = function()
		if not partner.dead then return true
		else return false
		end
	end
	
	actions["partnerDead"] = function()
		if partner.dead then return true
		else return false
		end
	end
	
	actions["partnerClose"] = function()
		if player:GetDistance(partner) <= config.followChamp.followDist then return true
		else return false
		end
	end
	
	--TODO: Implements
	actions["followFriend"] = function()
		
	end
	
	actions["friendClose"] = function()
		local friends = GetPlayers(player.team, false, false)
		local closest = friends[1]
		for i = 1, #friends, 1 do
			if player:GetDistance(friends[i]) < player:GetDistance(closest) then closest = friends[i] end
		end
		
		if player:GetDistance(closest) <= config.followChamp.followDist then return true
		else return false
		end
	end
	
	actions["inTurret"] = function()
		local tower = GetCloseTower(player, player.team)
		if player:GetDistance(tower) <= config.followChamp.followDist and player:GetDistance(GetSpawnPos()) < GetDistance(GetSpawnPos(), tower) then return true
		else return false
		end
	end
	
	actions["matchPartner"] = function()
		if partner == nil then
			local bottomPoint = Vector(12143, 2190)
			local myCarry = GetPlayers(player.team, false, false)
			partner = myCarry[1]
		
			for i = 2, #myCarry, 1 do
				if GetDistance(bottomPoint,myCarry[i]) < GetDistance(bottomPoint,partner) and myCarry[i]:GetDistance(allySpawn) > 5000 then
					partner = myCarry[i]		
				end
			end
			
			PrintChat("myPartner: "..partner.name)
			pAfk = false
			return true
		else
			return false
		end
	end
	
	actions["partnerRecalling"] = function()
		return pRecalling
	end
	
	actions["isRecalling"] = function()
		for i=1, objManager.maxObjects, 1 do
			local obj = objManager:getObject(i)
			if obj ~= nil and obj.valid and obj.name:find("TeleportHome") ~= nil and player:GetDistance(obj) < 70 then
				return true
			end
		end
		return false
	end
	
	actions["followPartner"] = function()
		followX = ((allySpawn.x - partner.x)/(partner:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + partner.x + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
		followZ = ((allySpawn.z - partner.z)/(partner:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + partner.z + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
			
		player:MoveTo(followX, followZ)
		
		return true
	end
	
	actions["goTurret"] = function()
		local target = GetCloseTower(player, player.team)
		player:MoveTo(player.x - target.x, player.z - target.z)
		return true
	end
	
	actions["towerFocusPlayer"] = function()
		return FocusOfTower
	end
	
	actions["runFromTower"] = function()
		local followX = (2 * myHero.x) - target.x
		local followZ = (2 * myHero.z) - target.z
		player:MoveTo(followX, followZ)
		
		return true
	end
	
	actions["recall"] = function()
		PrintChat("Recalling")
		CastSpell(RECALL)
		return true
	end
	
	local result = actions[self.action]()
	--if result then PrintChat("true") else PrintChat("false") end
	return result
end

--End of Classes area

--Util Section
function detectSpawnPoints()
	for i=1, objManager.maxObjects, 1 do
		local candidate = objManager:getObject(i)
		if candidate ~= nil and candidate.valid and candidate.type == "obj_SpawnPoint" then 
			if candidate.x < 3000 then 
				if player.team == TEAM_BLUE then allySpawn = candidate else enemySpawn = candidate end
			else 
				if player.team == TEAM_BLUE then enemySpawn = candidate else allySpawn = candidate end
			end
		end
	end
end

--return towers table
function GetTowers(team)
	local towers = {}
	for i=1, objManager.maxObjects, 1 do
		local tower = objManager:getObject(i)
		if tower ~= nil and tower.valid and tower.type == "obj_AI_Turret" and tower.visible and tower.team == team then
			table.insert(towers,tower)
		end
	end
	if #towers > 0 then
		return towers
	else
		return false
	end
end

function GetCloseTower(hero, team)
	local towers = GetTowers(team)
	if #towers > 0 then
		local candidate = towers[1]
		for i=2, #towers, 1 do
			if (towers[i].health/towers[i].maxHealth > 0.1) and  hero:GetDistance(candidate) > hero:GetDistance(towers[i]) then candidate = towers[i] end
		end
		return candidate
	else
		return false
	end
end

function GetPlayers(team, includeDead, includeSelf)
	local players = {}
	local result = {}
	
	if team == player.team then
		players = GetAllyHeroes()
	else
		players = GetEnemyHeroes()
	end
	
	for i=1, #players, 1 do
		if players[i].visible and (not players[i].dead or players[i].dead == includeDead) then
			table.insert(result, players[i])
		end
	end
	
	if 
		includeSelf then table.insert(result, player)
	else 
		for i=1, #result, 1 do
			if result[i] == player then
				table.remove(result, i)
				break
			end
		end
	end
	
	return result
end

function checkAfk()
	if partner ~= nil and collectTimer then
		if partner:GetDistance(allySpawn) < 5000 then
			lastPartnerMove = GetGameTimer()
			collectTimer = false
		end
	end
	
	if partner ~= nil and not collectTimer then
		if GetGameTimer() >= afkTimerCount + AFK_MAXTIME then
			pAfk = true
		elseif following:GetDistance(allySpawn) > 5000 then
			collectTimer = true
			pAfk = false
		end
	end
end

--End Util Section

function mountBehaviorTree()
	--1st level
	root = Sequence:new()
	sequence1 = Sequence:new()
	sequence2 = Sequence:new()
	sequence3 = Sequence:new()
	sequence4 = Sequence:new()
	sequence5 = Sequence:new()
	sequence6 = Sequence:new()
	sequence7 = Sequence:new() -- Attacked by tower
	
	selector1 = Selector:new()
	selector2 = Selector:new()
	selector3 = Selector:new()
	
	startTime 		= Action:new{action = "startTime"}
	noPartner 		= Action:new{action = "noPartner"}
	partnerAfk 		= Action:new{action = "partnerAfk"}
	matchPartner 	= Action:new{action = "matchPartner"}
	partnerAlive 	= Action:new{action = "partnerAlive"}
	partnerDead 	= Action:new{action = "partnerDead"}
	inTurret 		= Action:new{action = "inTurret"}
	recall 			= Action:new{action = "recall"}
	partnerClose 	= Action:new{action = "partnerClose"}
	followPartner 	= Action:new{action = "followPartner"}
	goTurret 		= Action:new{action = "goTurret"}
	partnerRecalling= Action:new{action = "partnerRecalling"}
	friendClose		= Action:new{action = "friendClose"}
	followFriend 	= Action:new{action = "followFriend"}
	towerFocusPlayer= Action:new{action = "towerFocusPlayer"}
	runFromTower	= Action:new{action = "runFromTower"}
	
	root:addChild(startTime)
	root:addChild(selector1)
	
	selector1:addChild(sequence1)
	selector1:addChild(sequence2)
	selector1:addChild(sequence3)
	selector1:addChild(sequence4)
	selector1:addChild(sequence7)
	
	sequence1:addChild(noPartner)
	sequence1:addChild(partnerAfk)
	sequence1:addChild(matchPartner)
	
	sequence7:addChild(towerFocusPlayer)
	sequence7:addChild(runFromTower)
	
	sequence2:addChild(partnerAlive)
	sequence2:addChild(selector2)
	
	sequence3:addChild(partnerDead)
	sequence3:addChild(selector3)
	
	sequence4:addChild(inTurret)
	sequence4:addChild(recall)
	
	selector2:addChild(sequence5)
	selector2:addChild(partnerClose)
	selector2:addChild(followPartner)
	
	selector3:addChild(sequence6)
	selector3:addChild(goTurret)
	
	sequence5:addChild(partnerRecalling)
	sequence5:addChild(partnerClose)
	sequence5:addChild(recall)
	
	sequence6:addChild(friendClose)
	sequence6:addChild(followFriend)
end

function OnDeleteObj(object)
	if object.name:find("yikes") then
		FocusOfTower = false
	elseif object.name:find("TeleportHome") and GetDistance(partner, object) < 70 then
		DelayAction(function() pRecalling = false end, 1, {0})
	end
end

function OnCreateObj(object)
	if object.name:find("yikes") then
		FocusOfTower = true
	elseif object.name:find("TeleportHome") and GetDistance(partner, object) < 70 then
		pRecalling = true
	end
end

function OnDraw()
	if partner ~= nil then DrawCircle(partner.x, partner.y, partner.z, 70, ARGB(200,255,255,0)) end
	if config.followChamp.drawFollowDist then DrawCircle(myHero.x, myHero.y, myHero.z, config.followChamp.followDist, ARGB(200,1,33,0)) end
end

function OnTick()
	if(config.enableScript)then
		root:run()
	end
end
--FIM DA AREA DE CLASSES

function drawMenu()
	config = scriptConfig("Passive Follow", "Passive Follow") 

	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONKEYTOGGLE, true, 115)
	  
	config:addSubMenu("Follow Champion", "followChamp")
	config:addSubMenu("Regen at Fountain", "fontRegen")
	config:addSubMenu("Auto use SumSpells", "autoSpells")
	config:addSubMenu("Auto Navigate: UNDER DEVELOPMENT", "autoNavigate")
	
	config.fontRegen:addParam("hpRegen", "min HP to leave", SCRIPT_PARAM_SLICE, DEFAULT_HP_REGEN, 0, 100, 0)
	config.fontRegen:addParam("manaRegen", "min Mana to leave", SCRIPT_PARAM_SLICE, DEFAULT_MANA_REGEN, 0, 100, 0)
	
	config.autoSpells:addParam("useHeal", "Auto use Heal", SCRIPT_PARAM_ONOFF, false)
	config.autoSpells:addParam("useClarity", "Auto use Clarity", SCRIPT_PARAM_ONOFF, false)
	
	config.autoSpells:addParam("manaThreshold", "Mana% for use Clarity", SCRIPT_PARAM_SLICE, DEFAULT_MANA_THRESHOLD, 0, 100, 0)
	config.autoSpells:addParam("healthThreshold", "HP% for use Cure", SCRIPT_PARAM_SLICE, DEFAULT_HEALTH_THRESHOLD, 0, 100, 0)
	
	config.followChamp:addParam("followDist", "Follow Distance", SCRIPT_PARAM_SLICE, DEFAULT_FOLLOW_DISTANCE, 400, 2000, 0)
	config.followChamp:addParam("drawFollowDist", "Draw Distance of Follow", SCRIPT_PARAM_ONOFF, true)
end

function initVariables()
	--summoners
	DEFAULT_FOLLOW_DISTANCE = 400
	DEFAULT_MANA_REGEN = 80
	DEFAULT_HP_REGEN = 80

	--CONSTANTS
	MIN_DISTANCE = 275
	HEAL_DISTANCE = 700
	DEFAULT_HEALTH_THRESHOLD = 70
	DEFAULT_MANA_THRESHOLD = 66

	AFK_MAXTIME = 120
	SCRIPT_START_TIME = os.clock() + 60
	lastPartnerMove = GetTickCount()
	
	-- GLOBALS
	FocusOfTower = false
	partner = nil
	temp_partner = nil
	pAfk = true
	pRecalling = false -- is Partner Recalling?

	-- spawn
	allySpawn = nil
	enemySpawn = nil

	detectSpawnPoints()
end


function OnLoad()
	player = GetMyHero()
	initVariables()
	drawMenu()
	mountBehaviorTree()
	PrintChat("Passive Follow Loaded")
	
	if AutoUpdate then
		Update()
	end
end
