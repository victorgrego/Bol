local version = "1.15"
--[[
    Passive Follow by VictorGrego.
]]
finishedOnLoad = false
initiated = false
FollowKeysText = {"F5", "F6", "F7", "F8"} --Key names for menu
FollowKeysCodes = {116,117,118,119} --Decimal key codes corressponding to key names
SetupDrawX = 0.1
SetupDrawY = 0.15
MenuTextSize = 18
allies = {}

--UPDATE SETTINGS
local AutoUpdate = true
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/victorgrego/BolSorakaScripts/master/GenericFollowAndWalk.lua?"..math.random(100)
local UPDATE_TMP_FILE = LIB_PATH.."GFWTmp.txt"
local versionmessage = "<font color=\"#81BEF7\" >Minor BugFix</font>"

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
		if pAfk then partner = nil end
		return pAfk
	end
	
	actions["partnerAlive"] = function()
		if partner ~= nil and not partner.dead then return true
		else return false
		end
	end
	
	actions["partnerDead"] = function()
		if partner ~= nil and  partner.dead then return true
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
			if friends[i] ~= nil and player:GetDistance(friends[i]) < player:GetDistance(closest) then closest = friends[i] end
		end
		
		if closest ~= nil and player:GetDistance(closest) <= config.followChamp.followDist then return true
		else return false
		end
	end
	
	actions["inTurret"] = function()
		local myTurret = GetCloseTower(player, player.team)
		if player:GetDistance(myTurret) <= config.followChamp.followDist and player:GetDistance(allySpawn) < GetDistance(allySpawn, myTurret) then return true
		else return false
		end
	end
	
	actions["matchPartner"] = function()
		if partner == nil then
			local myCarry = GetPlayers(player.team, false, false)
			local score = {}
			local maxScore = -1
			partner = nil
		
			for i = 1, #myCarry, 1 do
				score[i] = 0
				for j = 1, #myCarry, 1 do
					if GetDistance(myCarry[i], bottomPoint) < GetDistance(myCarry[j], bottomPoint) then score[i] = score[i] + 1 end
				end
				if GetDistance(bottomPoint, myCarry[i]) < 6000 then score[i] = score[i] + 5 end
				if GetDistance(allySpawn, myCarry[i]) < 5000 then score[i] = score[i] - 10000 end
			end
			
			for k = 1, #myCarry, 1 do
				if score[k] > maxScore and score[k] > 0 then
					maxScore = score[k]
					partner = myCarry[k]
				end
			end
			
			if partner ~= nil then
				PrintChat("myPartner: "..partner.name)
				pAfk = false
				lastPartnerMove = os.clock()
				return true
			else
				return false
			end
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
		local myTurret = GetCloseTower(player, player.team)
		followX = (allySpawn.x - myTurret.x)/(myTurret:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + myTurret.x
		followZ = (allySpawn.z - myTurret.z)/(myTurret:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + myTurret.z
		player:MoveTo(math.floor(followX), math.floor(followZ))
			
		return true
	end
	
	actions["towerFocusPlayer"] = function()
		return FocusOfTower
	end
	
	actions["runFromTower"] = function()
		local followX = (2 * myHero.x) - yikesTurret.x
		local followZ = (2 * myHero.z) - yikesTurret.z
		player:MoveTo(followX, followZ)
		
		return true
	end
	
	actions["recall"] = function()
		--PrintChat("Recalling")
		if not InFountain() then CastSpell(RECALL) end
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
	if partner ~= nil and GetDistance(partner, allySpawn) < 3000 then
		if os.clock() >= lastPartnerMove + AFK_MAXTIME then
			pAfk = true
		end
	elseif partner ~= nil then
		lastPartnerMove = os.clock()
		pAfk = false
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
	sequence8 = Sequence:new() -- Safe in turret
	
	selector1 = Selector:new()
	selector2 = Selector:new()
	selector3 = Selector:new()
	selector4 = Selector:new()
	selector5 = Selector:new() -- partner afk
	
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
	
	--lvl 1
	root:addChild(startTime)
	root:addChild(selector1)
	
	--lvl2
	selector1:addChild(sequence1)
	selector1:addChild(sequence7) -- flee from tower
	selector1:addChild(sequence2)
	selector1:addChild(sequence3)
	selector1:addChild(sequence4)
	
	--lvl3
	sequence1:addChild(selector5)
	sequence1:addChild(matchPartner)
	
	sequence7:addChild(towerFocusPlayer)
	sequence7:addChild(runFromTower)
	
	sequence2:addChild(partnerAlive)
	sequence2:addChild(selector2)
	
	sequence3:addChild(partnerDead)
	sequence3:addChild(selector3)
	
	sequence4:addChild(inTurret)
	sequence4:addChild(recall)
	
	--lvl 4
	selector5:addChild(partnerAfk)
	selector5:addChild(noPartner)
	
	selector2:addChild(sequence5)
	selector2:addChild(partnerClose)
	selector2:addChild(followPartner)
	
	--selector3:addChild(sequence6)
	selector3:addChild(selector4)
	
	--lvl 5
	sequence5:addChild(partnerRecalling)
	--sequence5:addChild(partnerClose)
	sequence5:addChild(recall)
	
	--sequence6:addChild(friendClose)
	--sequence6:addChild(followFriend)
	
	selector4:addChild(sequence8)
	selector4:addChild(goTurret)
	
	--lvl 6
	sequence8:addChild(inTurret)
	sequence8:addChild(recall)
end

function OnRecall(hero, channelTimeInMs)
    if hero.isMe then
        meRecalling = true
	elseif hero.name == partner.name then
		pRecalling = true
    end
end

function OnAbortRecall(hero)
    if hero.isMe then
        meRecalling = false
	elseif hero.name == partner.name then
		pRecalling = false
    end        
end

function OnFinishRecall(hero)
    if hero.isMe then
        meRecalling = false
	elseif hero.name == partner.name then
		pRecalling = false
    end
end

function OnDeleteObj(object)
	if object.name:find("yikes") then
		FocusOfTower = false
		yikesTurret = nil
	elseif object.name:find("TeleportHome") and GetDistance(partner, object) < 70 then
		DelayAction(function() 
		pRecalling = false 
		end, 0.5, {0})
	end
end

function OnCreateObj(object)
	if object.name:find("yikes") then
		FocusOfTower = true
		yikesTurret = GetCloseTower(player, TEAM_ENEMY)
	elseif object.name:find("TeleportHome") and GetDistance(partner, object) < 70 then
		pRecalling = true
	end
end

function drawFollowMenu()
	local tempSetupDrawY = SetupDrawY
	tempSetupDrawY = tempSetupDrawY + 0.03
	
	for i=1, #allies, 1 do
		DrawText("Press "..FollowKeysText[i].." to follow player: "..allies[i].name.." ("..allies[i].charName..")", MenuTextSize , (WINDOW_W - WINDOW_X) * SetupDrawX, (WINDOW_H - WINDOW_Y) * tempSetupDrawY , 0xffffff00) 
		tempSetupDrawY = tempSetupDrawY + 0.03
	end
end

function OnDraw()
	if partner ~= nil then DrawCircle(partner.x, partner.y, partner.z, 70, ARGB(200,255,255,0)) end
	if config.followChamp.drawFollowDist then DrawCircle(myHero.x, myHero.y, myHero.z, config.followChamp.followDist, ARGB(200,1,33,0)) end
	drawFollowMenu()
end

function OnTick()

	if(config.enableScript)then
		root:run()
	end
end

function OnWndMsg(msg, keycode)
	for i=1, #allies, 1 do 
		if keycode == FollowKeysCodes[i] and msg == KEY_DOWN then
			partner = allies[i]
			PrintChat("Passive Follow >> following summoner: "..allies[i].name)
		end
	end
end

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
	
	bottomPoint = Vector(12100, 2100)
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
	SCRIPT_START_TIME = os.clock() + 60 -- change the adc selecting time
	lastPartnerMove = nil
	
	FocusOfTower = false
	partner = nil
	temp_partner = nil
	pAfk = true
	pRecalling = false -- is Partner Recalling?
	meRecalling = false
	yikesTurret = nil
	collectTimer = true

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
	allies = GetPlayers(player.team, true, false)
	
	if AutoUpdate then
		Update()
	end
end

