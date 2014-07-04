--[[
    Passive Follow by ivan[russia]
	
    Updated for BoL by ikita
   
    Base wait for mana regen and health regen/summoner spell, follow menu added by One™
	 
	********************** updated and developed by B Boy Breaker for AFK fix ********************* 
	
	Code improvements and bug correction and latest updates by VictorGrego.
	
	Changes:
	- The recall when near a tower issue has been resolved
	- Recalls after tower, for best safety
	- Have a menu for dinamic adjust the distance
	- Now follow partner recall
]]
if myHero.charName ~= "Soraka" then return end
finishedOnLoad = false
initiated = false


function initVariables()
	--summoners
	DEFAULT_FOLLOW_DISTANCE = 400
	DEFAULT_MANA_REGEN = 80
	DEFAULT_HP_REGEN = 80
	isRecalling = false

	--CONSTANTS

	SetupFollowAlly = true 	-- you start follow near ally when your followtarget have been died
	SetupRunAway = true 		-- if no ally was near when followtarget died, you run to close tower
	MIN_DISTANCE = 275
	HEAL_DISTANCE = 700
	DEFAULT_HEALTH_THRESHOLD = 70
	DEFAULT_MANA_THRESHOLD = 66
	HL_slot = nil
	CL_slot = nil
	-- SETTINGS
	-- you can change true to false and false to true
	-- false is turn off
	-- true is turn on

	SetupToggleKey = 115 --Key to Toggle script. [ F4 - 115 ] default
						 --key codes
						 --http://www.indigorose.com/webhelp/ams/Program_Reference/Misc/Virtual_Key_Codes.htm

	SetupToggleKeyText = "F4"

	afktime = 180 -- the time if the adc is afk b4 change the follower per second


	-- GLOBALS [Do Not Change]

	SetupDebug = true
	following = nil
	temp_following = nil
	stopPosition = false
	breaker = false

	--state of app enum
	FOLLOW = 1
	TEMP_FOLLOW = -33
	WAITING_FOLLOW_RESP = 150
	GOING_TO_TOWER = 666
	RECALLING = 374

	--by default
	state = FOLLOW

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
end



-- ABSTRACTION-METHODS

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

-- STATUS CALLBACK
function Status(member)
	if member.dead and state == FOLLOW then
		PrintChat("Passive Follow >> "..member.name.." dead")
		-- if SetupFollowAlly == true and ALLYNEAR then temporary changing follow target
		if SetupFollowAlly and player:GetDistance(GetClosePlayer(player,player.team)) < config.followChamp.followDist then 
			temp_following = GetClosePlayer(player,player.team)
			PrintChat("Passive Follow >> "..(GetClosePlayer(player,player.team)).name.." temporary following")
			state = TEMP_FOLLOW
		elseif SetupRunAway then 
			state = GOING_TO_TOWER
		else
			state = WAITING_FOLLOW_RESP
		end
	end
	
	if not member.dead then
		if state == WAITING_FOLLOW_RESP then
			PrintChat("Passive Follow >> "..member.name.." alive")
			state = FOLLOW
		elseif state == TEMP_FOLLOW then
			temp_following = nil
			PrintChat("Passive Follow >> "..member.name.." alive")
			state = FOLLOW
		elseif state == GOING_TO_TOWER then
			PrintChat("Passive Follow >> "..member.name.." alive")
			state = FOLLOW
		end
	end
end

-- SEMICORE
-- run(follow) to target
function Run(target)
	if target.type == "AIHeroClient" then
		if target:GetDistance(allySpawn) > config.followChamp.followDist then
			if (player:GetDistance(target) > config.followChamp.followDist or player:GetDistance(target) < MIN_DISTANCE or player:GetDistance(allySpawn) + MIN_DISTANCE > target:GetDistance(allySpawn)) then
				followX = ((allySpawn.x - target.x)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.x + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
				followZ = ((allySpawn.z - target.z)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.z + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)))
				
				player:MoveTo(followX, followZ)
			else
				player:HoldPosition()
			end
		elseif SetupFollowRecall and player:GetDistance(allySpawn) > (config.followChamp.followDist * 2) then
			state = GOING_TO_TOWER
		end
	elseif target.type == "obj_AI_Turret" then 
		if player:GetDistance(target) > 100 then 
			followX = ((allySpawn.x - target.x)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.x)
			followZ = ((allySpawn.z - target.z)/(target:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + target.z)
			
			player:MoveTo(followX, followZ)
		else
			state = WAITING_FOLLOW_RESP
		end
	end
end

-- CORE
function Brain()
	if following ~= nil and not player.dead and isRecalling == false then 
		if state == FOLLOW then Run(following)
		elseif state == TEMP_FOLLOW and temp_following ~= nil then Run(temp_following)
		elseif state == GOING_TO_TOWER then Run(GetCloseTower(player,player.team)) 
		elseif state == WAITING_FOLLOW_RESP then CastSpell(RECALL) end
	end
end

--Drawing Script Menu
function drawMenu()
	config = scriptConfig("Passive Follow", "Passive Follow") 

	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONKEYTOGGLE, true, 115)
	  
	config:addSubMenu("Follow Champion", "followChamp")
	config:addSubMenu("Regen at Fountain", "fontRegen")
	config:addSubMenu("Auto use SumSpells", "autoSpells")
	
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
	if config.enableScript == true and unit.name == player.name and (spell.name == "SorakaBasicAttack" or spell.name == "SorakaBasicAttack2") then
		if(spell.target.name:find("Minion_")~=nil) then	player:MoveTo(player.x + math.random(-((config.followChamp.followDist-300)/3),((config.followChamp.followDist-300)/3)),player.z + math.random(-((config.followChamp.followDist-300)),((config.followChamp.followDist-300)))) end
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

-- CHAT CALLBACK
function OnSendChat(text)
	if string.sub(text,1,7) == ".follow" then
	BlockChat()
		if string.sub(text,9,13) == "start" then
			name = string.sub(text,15)
			players = GetPlayers(player.team, false, false)
			if players ~= false then
				for i=1, #players, 1 do
					if (string.lower(players[i].name) == string.lower(name))  then 
						following = players[i]
						PrintChat("Passive Follow >> following summoner: "..players[i].name)
						carryCheck = true
						if following.dead then state = WAITING_FOLLOW_RESP else state = FOLLOW end
					end
				end
				if following == nil then PrintChat("Passive Follow >> "..name.." did not found") end
			end
		end
		if string.sub(text,9,12) == "stop" then
			following = nil
			state = FOLLOW
			PrintChat("Passive Follow >> terminated")
		end
	end
end

-- Drawing follow menu
function OnDraw()
	local tempSetupDrawY = SetupDrawY

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
	if obj.name:find("TeleportHome.troy") then
		-- Set isRecalling off after short delay to prevent using abilities once at base
		DelayAction(function() isRecalling = false end, 0.2)
	end
end

--Detects if my partner is Recalling
function OnCreateObj(object)
	if object.name == "TeleportHomeImproved.troy" or object.name == "TeleportHome.troy" then
		if GetDistance(following, object) < 70 and player:GetDistance(following) <= config.followChamp.followDist then
			CastSpell(RECALL)
			isRecalling = true
		elseif GetDistance(player, object) < 70 then
			isRecalling = true
		end
	end
end

-- TIMER CALLBACK
mytime = GetTickCount() 

function OnTick()
	if not finishedOnLoad then return end
	-- if in fountain and has no mana/hp, wait to fill up mana/hp bar before heading back out
	-- fix for 4.11
	if InFountain() and (player.mana/player.maxMana * 100 < config.fontRegen.manaRegen or player.health/player.maxHealth * 100 < config.fontRegen.hpRegen) then
		if isRegen == false then
			PrintChat("Passive Follow >> Waiting at fountain to replenish mana and health.")
			isRegen = true
		end
		player:HoldPosition()
	elseif not isRecalling then
		isRegen = false
		
		-- if there is no one go to bot "no adc(follower target)"
		if carryCheck == false and breaker == false and os.clock() >= breakers + afktime and following == nil then
			local toFollow = GetPlayers(player.team, true, false)
			for i = 1, #toFollow, 1 do --get heros
				if toFollow[i].name ~= following.name and following:GetDistance(allySpawn) > 5000 then 
					following = toFollow[i]
					PrintChat("Passive Follow >> following summoner: "..toFollow[i].name)
					state = FOLLOW
					carryCheck = true
					breakers = os.clock()
				end
			end
		end
		
		-- if the target is afk
		if carryCheck == true and breaker == false then
			if following:GetDistance(allySpawn) < 5000 then
				breakers = os.clock()
				breaker = true
			end
		end

		-- if the target moved again after afk "maybe the adc recall or die"
		if carryCheck == true and breaker == true then
			if following:GetDistance(allySpawn) > 5000 then
				breaker = false
			end
		end
		
		-- choose new hero to follow
		if os.clock() >= breakers + afktime and breaker == true then 
			
			for i = 1, heroManager.iCount, 1 do --get heros

				local teammates = heroManager:getHero(i)

				if teammates.team == player.team and teammates.name ~= player.name and teammates.name ~= following.name and following:GetDistance(allySpawn) > 5000 then --check if hero is alive, in my team(!) and not the same like before
				
					following = teammates
					PrintChat("Passive Follow >> following summoner: "..teammates.name)

					state = FOLLOW
					breaker = false
				end
			end
		end

		--Identify AD carry and follow
		if carryCheck == false then
			--TODO: Check if includeDead affects
			local myCarry = GetPlayers(player.team, true, false)
			for i = 1, #myCarry, 1 do
				--Coordinates are for bottom lane only
				if math.sqrt((myCarry[i].x - 12143)^2 + (myCarry[i].z - 2190)^2) < 4500 then
					following = myCarry[i]
					PrintChat("Passive Follow >> following summoner: "..myCarry[i].name)
					state = FOLLOW
					carryCheck = true
				end
			end
		end

		if GetTickCount() - mytime > 800 and config.enableScript then 
			Brain()
			mytime = GetTickCount() 
		end
		
		if following ~= nil then
			Status(following)
		end
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
end

-- AT LOADING OF SCRIPT
function OnLoad()
	
	player = GetMyHero()
	initVariables()
	breakers = os.clock()   --start timer
	carryCheck = false
	PrintChat("Passive Follow >> LOADED")
	
	setSummonerSlots()
	detectSpawnPoints()
	
	--set allies player list
	allies = GetPlayers(player.team, true, false)
	drawMenu()
	finishedOnLoad = true
end
