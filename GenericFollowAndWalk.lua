local version = "1.09"
--[[
    Freely based in Passive Follow by ivan[russia]
	Code improvements and bug correction and latest updates by VictorGrego.
	
	Changes:
	- The recall when near a tower issue has been resolved
	- Recalls after tower, for best safety
	- Have a menu for dinamic adjust the distance
	- Now follow partner recall
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

--starting Variables
function initVariables()
	--summoners
	DEFAULT_FOLLOW_DISTANCE = 400
	DEFAULT_MANA_REGEN = 80
	DEFAULT_HP_REGEN = 80

	--CONSTANTS

	SetupFollowAlly = true 	-- you start follow near ally when your followtarget have been died
	SetupRunAway = true 	-- if no ally was near when followtarget died, you run to close tower
	MIN_DISTANCE = 275
	FOLLOW_LIMIAR = 500
	HEAL_DISTANCE = 700
	DEFAULT_HEALTH_THRESHOLD = 70
	DEFAULT_MANA_THRESHOLD = 66
	HL_slot = nil
	CL_slot = nil

	SetupToggleKey = 115 --Key to Toggle script. [ F4 - 115 ] default


	SetupToggleKeyText = "F4"

	AFK_MAXTIME = 120
	INIT_CHOOSE_TIME = 60
	INIT_GAME_TIME = nil
	wanderPoint = nil
	lastWander = GetTickCount()
	
	moveDelay = 333
	lastMove = GetTickCount()
	
	-- GLOBALS

	SetupDebug = true
	following = nil
	temp_following = nil
	stopPosition = false
	partnerAfk = true
	havePartner = false

	--state of app enum
	FOLLOW = 1
	TEMP_FOLLOW = "TEMPORARY_FOLLOWING"
	SEARCHING_PARTNER = "SEARCHING_PARTNER"
	GO_TOWER = "GOING_TO_TOWER"
	RECALLING = "RECALLING"
	AVOID_TOWER = "AVOIDING_TOWER"
	WAITING_RESSURECT = "WAITING_RESSURECT"

	--by default
	state = SEARCHING_PARTNER

	-- spawn
	allySpawn = nil
	enemySpawn = nil

	--player status
	isRegen = false
	manaRegenPercent = 0.8
	healthRegenPercent = 0.8

	--follow menu
	SetupDrawX = 0.1
	SetupDrawY = 0.15
	MenuTextSize = 18

	allies = {}
	FollowKeysText = {"F5", "F6", "F7", "F8"} --Key names for menu
	FollowKeysCodes = {116,117,118,119} --Decimal key codes corressponding to key names
	initiated = true
	focusing = nil
	lastFocused = nil
end

--return players table
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

--here get close tower
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

--here get close player
function GetClosePlayer(hero, team)
	local players = GetPlayers(team,false,false)
	if #players > 0 then
		local candidate = players[1]
		for i=2, #players, 1 do
			if hero:GetDistance(candidate) > hero:GetDistance(players[i]) then candidate = players[i] end
		end
		return candidate
	else
		return false
	end
end

-- SEMICORE
-- run(follow) to target
function Run(target)
	if target.type == "AIHeroClient" then
		if target.dead then return false end
		if target.dead and InFountain() then return true end
		if target:GetDistance(allySpawn) > config.followChamp.followDist then
			if (player:GetDistance(target) > config.followChamp.followDist + FOLLOW_LIMIAR or player:GetDistance(target) < MIN_DISTANCE or player:GetDistance(allySpawn) + MIN_DISTANCE > target:GetDistance(allySpawn)) then
				followX = ((allySpawn.x - target.x)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.x + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
				followZ = ((allySpawn.z - target.z)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.z + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
				
				iMove(followX, followZ)
				wander(target)
			else
				if (wanderPoint == nil or (player.x == wanderPoint.x and player.z == wanderPoint.z)) then
					wander(target)
				else
					iMove(wanderPoint.x, wanderPoint.z)
				end
			end
		end
		return true
	elseif target.type == "obj_AI_Turret" and target.team == player.team then 
		if player:GetDistance(target) > 200 then 
			followX = ((allySpawn.x - target.x)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.x)
			followZ = ((allySpawn.z - target.z)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.z)
			player:MoveTo(math.floor(followX), math.floor(followZ))
			return true
		else
			return false
		end
	elseif target.type == "obj_AI_Turret" and target.team ~= player.team then 
		if (UnderTurret(player, true)) then
			
			local followX = (2 * myHero.x) - target.x
			local followZ = (2 * myHero.z) - target.z
			
			player:MoveTo(followX, followZ)
			return true
		else
			return false
		end
	end
end

function wander(center)
	local v1 = Vector(center.x + math.floor(math.random(-FOLLOW_LIMIAR,FOLLOW_LIMIAR)), center.z + math.floor(math.random(-FOLLOW_LIMIAR, FOLLOW_LIMIAR)))
	local v2 = Vector(center)
	local aux = Vector(center)
	--local angle = aux:angleBetween(v1,v2)
	local radius = math.floor(math.random(MIN_DISTANCE, FOLLOW_LIMIAR))
	local angle = math.floor(math.random(1,360))
	
	local followX = center.x + radius * math.cos(math.rad(angle))
	local followY = center.y + radius * math.sin(math.rad(angle))
	local followZ = center.z + radius * math.sin(math.rad(angle))
	
	wanderPoint = {x = followX, y = followY, z = followZ}
	lastWander = GetTickCount()
end

function iMove(x,z)
	if GetTickCount() < lastMove + moveDelay then return end
	
	if player.x ~= x and player.z ~= z then player:MoveTo(x, z)
	else wander(following) end
	lastMove = GetTickCount()
end

-- CORE
function Brain()
	--if following ~= nil and not player.dead then 
	if state == RECALLING then 
		if InFountain() then state = WAITING_RESSURECT
		else CastSpell(RECALL) end
		return false
	elseif state == FOLLOW then
		--[[if focusing ~= nil and focusing.type == "obj_AI_Turret" and focusing.team ~= player.team then 
			player:Attack(focusing) 
		end]]
		if player.dead then return false end
		local result = Run(following)
		if not result then
			local closest = GetClosePlayer(myHero, player.team)
			if closest and myHero:GetDistance(closest) < 750 then
				temp_following = closest
				state = TEMP_FOLLOW
			else
				state = GO_TOWER
			end
		end
	elseif state == TEMP_FOLLOW then 
		if following.dead then Run(temp_following)
		else state = FOLLOW end
	elseif state == GO_TOWER then 
		local result = Run(GetCloseTower(player,player.team)) 
		if not result then
			state = RECALLING
		end
	elseif state == SEARCHING_PARTNER then 
		if SearchingPartner() then state = FOLLOW end
	elseif state == AVOID_TOWER then
		local result = Run(GetCloseTower(player,TEAM_ENEMY)) 
		if not result then
			state = FOLLOW
		end
	elseif start == WAITING_RESSURECT then
		if not following.dead then state = FOLLOW end
	end
	return true
	--end
end

--Drawing Script Menu
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

--TODO: Support other Spells
--Set Heal and Clarity
function setSummonerSlots()
	--set clarity
	if player:GetSpellData(SUMMONER_1).name == "SummonerMana" then
		CL_slot = SUMMONER_1
		HL_slot = SUMMONER_2
	elseif player:GetSpellData(SUMMONER_2).name == "SummonerMana" then
		HL_slot = SUMMONER_1
		CL_slot = SUMMONER_2
	end
end

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

-- Auto Called Methods

function OnProcessSpell(unit,spell)
	if not finishedOnLoad then return end
	
	if spell.name:lower():find("attack")~=nil and unit.name == following.name and spell.target.type:lower():find("turret") ~= nil then
		--PrintChat("Spell Created: "..spell.target.type)
		focusing = spell.target
	end
end

-- turn (off - on) by SetupToggleKey
-- follow summoners via follow menu
function OnWndMsg(msg, keycode)
	for i=1, #allies, 1 do 
		if keycode == FollowKeysCodes[i] and msg == KEY_DOWN then
			following = allies[i]
			PrintChat("Passive Follow >> following summoner: "..allies[i].name)
			state = FOLLOW
		end
	end
end

-- Drawing follow menu
function OnDraw()
	local tempSetupDrawY = SetupDrawY
	--DrawCircle(12143, 0, 2190, 200, ARGB(255,255,0,0))
	--if wanderPoint~= nil then DrawLine3D(player.x, player.y, player.z, wanderPoint.x, wanderPoint.y, wanderPoint.z, 1, ARGB(255,255,255,255)) end
	
	DrawText("Press "..SetupToggleKeyText.." to toggle passive follow script.", MenuTextSize , (WINDOW_W - WINDOW_X) * SetupDrawX, (WINDOW_H - WINDOW_Y) * tempSetupDrawY , 0xffffff00) 
	tempSetupDrawY = tempSetupDrawY + 0.03
	
	if config.followChamp.drawFollowDist then DrawCircle(myHero.x, myHero.y, myHero.z, config.followChamp.followDist, ARGB(200,1,33,0)) end
	
	for i=1, #allies, 1 do
		DrawText("Press "..FollowKeysText[i].." to follow player: "..allies[i].name.." ("..allies[i].charName..")", MenuTextSize , (WINDOW_W - WINDOW_X) * SetupDrawX, (WINDOW_H - WINDOW_Y) * tempSetupDrawY , 0xffffff00) 
		tempSetupDrawY = tempSetupDrawY + 0.03
	end
end

-- OnDeleteObj
function OnDeleteObj(obj)
	if obj.name:find("TeleportHome") ~= nil then
		if (GetDistance(following, obj) < 70 and player:GetDistance(following) <= config.followChamp.followDist+ FOLLOW_LIMIAR) or player:GetDistance(obj) < 70 then
			DelayAction(function() player:MoveTo(player.x, player.z)
			state = FOLLOW end,0.5)
		end
	end
end

--Detects if my partner is Recalling
function OnCreateObj(object)
	if object.name:find("TeleportHome") ~= nil  then
		if GetDistance(following, object) < 70 and player:GetDistance(following) <= config.followChamp.followDist + FOLLOW_LIMIAR then
			state = RECALLING
			CastSpell(RECALL)
		elseif GetDistance(player, object) < 70 then
			state = RECALLING
			CastSpell(RECALL)
		end
	elseif object.name:find("yikes") then
		state = AVOID_TOWER
	end
end

function SearchingPartner()
	if(GetGameTimer() < INIT_CHOOSE_TIME + INIT_GAME_TIME) then return end
	local bottomPoint = Vector(12143, 2190)
	local myCarry = GetPlayers(player.team, false, false)
	following = myCarry[1]
	havePartner = true
	partnerAfk = false
	
	for i = 2, #myCarry, 1 do
		if GetDistance(bottomPoint,myCarry[i]) < GetDistance(bottomPoint,following) then
			following = myCarry[i]		
		end
	end
	
	PrintChat("Passive Follow >> following summoner: "..following.name)
	return true
end

function useSummonerSpell()
	-- use Heal if you hp is low (currently buggy)
	if (following ~= nil and following.dead == false and (following.health/following.maxHealth) * 100 < config.autoSpells.healthThreshold and player:GetDistance(following) <= HEAL_DISTANCE) or (player.health/player.maxHealth) * 100 < config.autoSpells.healthThreshold then
		if HL_slot ~= nil and player:CanUseSpell(HL_slot) == READY then
			PrintChat("Passive Follow >> Used summoner spell.")
			CastSpell(HL_slot)
		end
	end
		
	-- use Clarity if your mana is low 
	if (player.mana/player.maxMana) * 100 < config.autoSpells.manaThreshold then
		if CL_slot ~= nil and player:CanUseSpell(CL_slot) == READY then
			PrintChat("Passive Follow >> Used summoner spell: CLARITY.")
			CastSpell(CL_slot)
		end
	end
end 

function followAnyAfterTime()
	-- If noone after bot, then follow any!
	--if carryCheck then PrintChat("carryCheck") else PrintChat("noCarryCheck") end
	--if partnerAfk then PrintChat("partnerAfk") else PrintChat("noPartnerAfk") end
	if not havePartner and partnerAfk then
		local toFollow = GetPlayers(player.team, true, false)
		for i = 1, #toFollow, 1 do --get heros
			if toFollow[i]:GetDistance(allySpawn) > 5000 then 
				following = toFollow[i]
				PrintChat("Passive Follow >> following summoner: "..toFollow[i].name)
				state = FOLLOW
				havePartner = true
				afkTimerCount = GetGameTimer()
			end
		end
	end
end

function checkPartnerAfk()
	-- Check if target is at base, and activate a timer.
	if havePartner and not partnerAfk then
		if following:GetDistance(allySpawn) < 5000 then
			afkTimerCount = GetGameTimer()
			partnerAfk = true
		end
	end

	-- If tolerance time finished, search for new partner, else continue following previous.
	if havePartner and partnerAfk then
		if GetGameTimer() >= afkTimerCount + AFK_MAXTIME then
			havePartner = false
			followAnyAfterTime()
		elseif following:GetDistance(allySpawn) > 5000 then
			partnerAfk = false
		end
	end
	
	if not havePartner and partnerAfk and GetGameTimer() >= afkTimerCount + AFK_MAXTIME then
		followAnyAfterTime()
	end
end


function OnTick()
	if not finishedOnLoad or not config.enableScript then return end
	-- if in fountain and has no mana/hp, wait to fill up mana/hp bar before heading back out
	if InFountain() and (player.mana/player.maxMana * 100 < config.fontRegen.manaRegen or player.health/player.maxHealth * 100 < config.fontRegen.hpRegen) then
		PrintChat("Passive Follow >> Waiting at fountain to replenish mana and health.")
		player:HoldPosition()
	else
		isRegen = false
		
		if not Brain() then return end
		checkPartnerAfk()
		useSummonerSpell()
	end
end

-- AT LOADING OF SCRIPT
function OnLoad()
	
	player = GetMyHero()
	initVariables()
	afkTimerCount = GetGameTimer()   --start timer
	INIT_GAME_TIME = GetGameTimer()
	PrintChat("Passive Follow >> LOADED")
	
	setSummonerSlots()
	detectSpawnPoints()
	
	--set allies player list
	allies = GetPlayers(player.team, true, false)
	drawMenu()
	finishedOnLoad = true
	
	if AutoUpdate then
		Update()
	end
end
