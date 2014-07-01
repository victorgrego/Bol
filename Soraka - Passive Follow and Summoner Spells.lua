--[[
    Passive Follow by ivan[russia]
	
    Updated for BoL by ikita
   
    Base wait for mana regen and health regen/summoner spell, follow menu added by One™, code improvements and bug correction by VictorGrego.
	 
********************** updated and developed by B Boy Breaker for AFK fix ********************* 
]]

require "MapPosition"

--summoners
local DEFAULT_FOLLOW_DISTANCE = 400
local DEFAULT_MANA_REGEN = 80
local DEFAULT_HP_REGEN = 80

-- SETTINGS
do
-- you can change true to false and false to true
-- false is turn off
-- true is turn on

SetupToggleKey = 115 --Key to Toggle script. [ F4 - 115 ] default
					 --key codes
					 --http://www.indigorose.com/webhelp/ams/Program_Reference/Misc/Virtual_Key_Codes.htm

SetupToggleKeyText = "F4"

SetupFollowAlly = true
-- you start follow near ally when your followtarget have been died

SetupRunAway = true
-- if no ally was near when followtarget died, you run to close tower

SetupRunAwayRecall = true
-- if you succesfully recall after followtarget died or recalled, you start recall

SetupFollowRecall = true
-- should you recall as soon as follow target racalled

SetupAutoHold = true -- Need work
-- stop autohit creeps when following target

afktime = 180 -- the time if the adc is afk b4 change the follower per second
end

-- GLOBALS [Do Not Change]
do
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

version = 2.2
player = GetMyHero()
end

recallStartTime = 0
recallDetected = false

recentrecallTarget = player

-- ABSTRACTION-METHODS

--return players table
function GetPlayers(team, includeDead, includeSelf)
	local players = {}
	for i=1, heroManager.iCount, 1 do
		local member = heroManager:getHero(i)
		if member ~= nil and member.valid and member.type == "obj_AI_Hero" and member.visible and member.team == team then
			if member.name ~= player.name or includeSelf then 
				if includeDead then
					table.insert(players,member)
				elseif member.dead == false then
					table.insert(players,member)
				end
			end
		end
	end
	if #players > 0 then
		return players
	else
		return false
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

-- return count of champs near hero
function cntOfChampsNear(hero,team,distance)
	local cnt = 0 -- default count of champs near HERO
	local players = GetPlayers(team,false,true)
	for i=1, #players, 1 do
		if players[i] ~= hero and hero:GetDistance(players[i]) < distance then cnt = cnt + 1 end
	end
	return cnt
end

-- return %hp of champs near hero
function hpOfChampsNear(hero,team,distance)
	local percent = 0 -- default %hp of champs near HERO
	local players = GetPlayers(team,false, true)
	for i=1, #players, 1 do
		if players[i] ~= hero and hero:GetDistance(players[i]) < distance then percent = percent + players[i].health/players[i].maxHealth end
	end
	return percent
end

function OnProcessSpell(object,spellProc) --for soraka + sona
	if config.enableScript == true and object.name == player.name and (spellProc.name == "SonaHymnofValorAttack" or spellProc.name == "SonaAriaofPerseveranceAttack" or spellProc.name == "SonaBasicAttack" or spellProc.name == "SonaBasicAttack2" or spellProc.name == "SonaSongofDiscordAttack" or spellProc.name == "SorakaBasicAttack" or spellProc.name == "SorakaBasicAttack2") then
		Run(GetCloseTower(player,player.team))
	end
end

-- is recall, return true/false
function isRecall(hero)
	if GetTickCount() - recallStartTime > 8000 then
		return false
	else
		if recentrecallTarget.name == hero.name then
			return true
		end
		return false
	end
end

function OnCreateObj(object)
	if object.name == "TeleportHomeImproved.troy" or object.name == "TeleportHome.troy" then
		for i = 1, heroManager.iCount do
			local target = heroManager:GetHero(i)
			if GetDistance(target, object) < 100 then
				recentrecallTarget = target
			end
		end
		recallStartTime = GetTickCount()
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
			players = GetPlayers(player.team, true, false)
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



-- TIMER CALLBACK
mytime = GetTickCount() 

function OnTick()

	-- if in fountain and has no mana/hp, wait to fill up mana/hp bar before heading back out
	if InFountain() and (player.mana/player.maxMana * 100 < config.fontRegen.manaRegen or player.health/player.maxHealth * 100 < config.fontRegen.hpRegen) then
		if isRegen == false then
			PrintChat("Passive Follow >> Waiting at fountain to replenish mana and health.")
			isRegen = true
		end
		player:HoldPosition()
	else
		isRegen = false

		-- if there is no one go to bot "no adc(follower target)"
		if carryCheck == false and breaker == false and os.clock() >= breakers + afktime and following == nil then
			for i = 1, heroManager.iCount, 1 do --get heros
				local teammates = heroManager:getHero(i)
				if teammates.team == player.team and teammates.name ~= player.name and teammates.name ~= following and MapPosition:inBase(teammates) == false then 
					
					following = teammates
					PrintChat("Passive Follow >> following summoner: "..teammates.name)
					state = FOLLOW
					carryCheck = true
					breakers = os.clock()
				end
			end
		end
		
		-- if the target is afk
		if carryCheck == true and breaker == false then
			if MapPosition:inBase(following) == true then
				breakers = os.clock()
				breaker = true
			end
		end

		-- if the target moved again after afk "maybe the adc recall or die"
		if carryCheck == true and breaker == true then
			if MapPosition:inBase(following) == false then
				breaker = false
			end
		end
		
		-- choose new hero to follow
		if os.clock() >= breakers + afktime and breaker == true then 
			
			for i = 1, heroManager.iCount, 1 do --get heros

				local teammates = heroManager:getHero(i)

				if teammates.team == player.team and teammates.name ~= player.name and teammates.name ~= following and MapPosition:inBase(teammates) == false then --check if hero is alive, in my team(!) and not the same like before
				
					following = teammates
					PrintChat("Passive Follow >> following summoner: "..teammates.name)

					state = FOLLOW
					breaker = false
				end
			end
		end

		--Identify AD carry and follow
		if carryCheck == false then
			for i = 1, heroManager.iCount, 1 do
			local teammates = heroManager:getHero(i) 
			--Coordinates are for bots only
				if math.sqrt((teammates.x - 12143)^2 + (teammates.z - 2190)^2) < 4500 and teammates.team == player.team and teammates.name ~= player.name then
					following = teammates
					PrintChat("Passive Follow >> following summoner: "..teammates.name)
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
			Status(following, 1, value)
		end
	end
end

-- STATUS CALLBACK
function Status(member, desc, value)
	if member == following and desc == 1 then
		if member.dead and state == FOLLOW then
			PrintChat("Passive Follow >> "..member.name.." dead")
			-- if SetupFollowAlly == true and ALLYNEAR then temporary changing follow target
			if SetupFollowAlly and player:GetDistance(GetClosePlayer(player,player.team)) < DEFAULT_FOLLOW_DISTANCE then 
				temp_following = GetClosePlayer(player,player.team)
				PrintChat("Passive Follow >> "..(GetClosePlayer(player,player.team)).name.." temporary following")
				state = TEMP_FOLLOW
			elseif SetupRunAway then 
				state = GOING_TO_TOWER
			else
				state = WAITING_FOLLOW_RESP
			end
		end
		if member.dead == false then
			if state == WAITING_FOLLOW_RESP then
				PrintChat("Passive Follow >> "..member.name.." alive")
				state = FOLLOW
			end
			if state == TEMP_FOLLOW then
				temp_following = nil
				PrintChat("Passive Follow >> "..member.name.." alive")
				state = FOLLOW
			end
			if state == GOING_TO_TOWER then
				PrintChat("Passive Follow >> "..member.name.." alive")
				state = FOLLOW
			end
		end
	end
end

-- SEMICORE
-- run(follow) to target
function Run(target)
	if target.type == "obj_AI_Hero" then
		if target:GetDistance(allySpawn) > DEFAULT_FOLLOW_DISTANCE then
			if (player:GetDistance(target) > DEFAULT_FOLLOW_DISTANCE or player:GetDistance(target) < 275 --[[this is to stop get aoe, which are often 275 range]] or player:GetDistance(allySpawn) + 275 > target:GetDistance(allySpawn)) then
				followX = ((allySpawn.x - target.x)/(target:GetDistance(allySpawn)) * ((DEFAULT_FOLLOW_DISTANCE - 300) / 2 + 300) + target.x + math.random(-((DEFAULT_FOLLOW_DISTANCE-300)/3),((DEFAULT_FOLLOW_DISTANCE-300)/3)))
				followZ = ((allySpawn.z - target.z)/(target:GetDistance(allySpawn)) * ((DEFAULT_FOLLOW_DISTANCE - 300) / 2 + 300) + target.z + math.random(-((DEFAULT_FOLLOW_DISTANCE-300)/3),((DEFAULT_FOLLOW_DISTANCE-300)/3)))
				player:MoveTo(followX, followZ)
			else
				player:HoldPosition()
			end
		elseif SetupFollowRecall and player:GetDistance(allySpawn) > (DEFAULT_FOLLOW_DISTANCE * 2) then
			state = GOING_TO_TOWER
		end
	end
	if target.type == "obj_AI_Turret" then 
		if player:GetDistance(target) > 300 then 
			player:MoveTo(target.x + math.random(-150,150), target.z + math.random(-150,150))
		elseif SetupRunAwayRecall then
			CastSpell(RECALL)
			if following.dead == true then
				state = WAITING_FOLLOW_RESP
			else
				state = FOLLOW
			end
		end
	end
end

-- CORE
function Brain()
	if following ~= nil and player.dead == false and isRecall(player) == false then 
		if state == FOLLOW then 
			Run(following) 
		end
		if state == TEMP_FOLLOW and temp_following ~= nil then Run(temp_following) end
		if state == GOING_TO_TOWER then Run(GetCloseTower(player,player.team)) end
		
	end
end

-- Drawing follow menu
function OnDraw()
	local tempSetupDrawY = SetupDrawY

	DrawText("Press "..SetupToggleKeyText.." to toggle passive follow script.", MenuTextSize , (WINDOW_W - WINDOW_X) * SetupDrawX, (WINDOW_H - WINDOW_Y) * tempSetupDrawY , 0xffffff00) 
	tempSetupDrawY = tempSetupDrawY + 0.03
	
	for i=1, #allies, 1 do
		DrawText("Press "..FollowKeysText[i].." to follow player: "..allies[i].name.." ("..allies[i].charName..")", MenuTextSize , (WINDOW_W - WINDOW_X) * SetupDrawX, (WINDOW_H - WINDOW_Y) * tempSetupDrawY , 0xffffff00) 
		tempSetupDrawY = tempSetupDrawY + 0.03
	end
end

--Drawing Script Menu
function drawMenu()
	config = scriptConfig("Passive Follow", "Passive Follow") 

	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONKEYTOGGLE, true, 115)
	  
	config:addSubMenu("Follow Champion", "followChamp")
	config:addSubMenu("Regen at Fountain", "fontRegen")
	
	config.fontRegen:addParam("hpRegen", "min HP to leave", SCRIPT_PARAM_SLICE, DEFAULT_HP_REGEN, 0, 100, 0)
	config.fontRegen:addParam("manaRegen", "min Mana to leave", SCRIPT_PARAM_SLICE, DEFAULT_MANA_REGEN, 0, 100, 0)
	
	config.followChamp:addParam("followDist", "Follow Distance", SCRIPT_PARAM_SLICE, DEFAULT_FOLLOW_DISTANCE, 400, 1000, 0)
end

-- AT LOADING OF SCRIPT
function OnLoad()
	breakers = os.clock()   --start timer
	PrintChat("Passive Follow >> v"..tostring(version).." LOADED")
	carryCheck = false
	
	-- numerate spawn
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
	
	--set allies player list
	allies = GetPlayers(player.team, true, false)
	drawMenu()
end
