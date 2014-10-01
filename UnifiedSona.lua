local version = "1.01"
--[[

--]]

-- Champion Check
require 'VPrediction'

if myHero.charName ~= "Sona" then return end


--UPDATE SETTINGS
local AutoUpdate = true
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/victorgrego/Bol/master/UnifiedSona.lua?"..math.random(100)
local UPDATE_TMP_FILE = LIB_PATH.."UNSTmp.txt"
local versionmessage = "<font color=\"#81BEF7\" >Changelog:Minor optimizations</font>"

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
				PrintChat("<font color=\"#81BEF7\" >UnifiedSona:</font> <font color=\"#00FF00\">Successfully updated to: v"..Version..". Please reload the script with F9.</font>")
			else
				PrintChat("<font color=\"#81BEF7\" >UnifiedSona:</font> <font color=\"#FF0000\">Error updating to new version (v"..Version..")</font>")
			end
			elseif (Version ~= nil) and (Version == tonumber(version)) then
				PrintChat("<font color=\"#81BEF7\" >UnifiedSona:</font> <font color=\"#00FF00\">No updates found, latest version: v"..Version.." </font>")
			end
		end
	end
end

--build
shopList = {
	3301,-- coin
	3340,--ward trinket
	1004,1004,--Faerie Charm
	3028,
	--1028,--Ruby Crystal
	--2049,--Sighstone
	3096,--Nomad Medallion
	3114,--Forbidden Idol
	3069,--Talisman of Ascension
	1001,--Boots 
	3108,--Fiendish Codex
	3174,--Athene's Unholy Grail
	--2045,--Ruby Sighstone
	1028,--Ruby Crystal
	1057,--Negatron Cloak
	3105,--Aegis of Legion
	3158,--Ionian Boots
	1011,--Giants Belt
	3190,--Locket of Iron Solari
	3143,--Randuins
	3275,--Homeguard
	1058,--Large Rod
	3089--Rabadon
}

levelSequence = {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E}
ts = TargetSelector(TARGET_LOW_HP, 650, DAMAGE_MAGIC, true)

nextbuyIndex = 1
lastBuy = 0

buyDelay = 100 --default 100

-------Orbwalk info-------
local lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
local myTrueRange = 0
local myTarget = nil
-------/Orbwalk info-------


-- Constants (do not change)
local powerChordCount = 0
local Q_RANGE = 650
local W_RANGE = 1000
local E_RANGE = 360
local R_RANGE = 900
local SONA_RANGE = 550

local DEFAULT_HARASS_MIN_MANA = 30
local DEFAULT_HEAL_MIN_MANA = 10
local DEFAULT_HEAL_THRESHOLD = 50

function chordCount()
	if powerChordCount < 3 then powerChordCount = powerChordCount + 1
	else powerChordCount = 0 end 
end

function isPowerChord()
	if powerChordCount > 2 then return true
	else return false end
end

function Behavior()
	friends = GetPlayers(player.team, false, true, W_RANGE)
	enemies = GetPlayers(TEAM_ENEMY, false, false, Q_RANGE)
	Efriends = GetPlayers(player.team, false, true, E_RANGE)
	AAenemies = GetPlayers(TEAM_ENEMY, false, false, SONA_RANGE)
	
	--autoQ
	if enemies ~= nil and #enemies > 0 and getManaPercent() > config.autoHarass.harassMinMana and player:CanUseSpell(_Q) == READY then
		CastSpell(_Q)
	end
	
	--autoW
	if friends ~= nil and #friends > 0 and getManaPercent() > config.autoHeal.healMinMana and player:CanUseSpell(_W) == READY then
		for i = 1, #friends, 1 do
			if getHealthPercent(friends[i]) < config.autoHeal.healThreshold then
				CastSpell(_W)
				break
			end
		end
	end
	
	--autoE
	if friends ~= nil and #friends > 0 and player:CanUseSpell(_E) == READY and getManaPercent() > config.autoCelerity.celerityMinMana then
		for i = 1, #Efriends, 1 do
			if Efriends[i].isFleeing then
				CastSpell(_E)
				break
			end
		end
	end
	
	if ts.target == nil or not config.autoUlt.enabled then return end
	local AOECastPosition, MainTargetHitChance, nTargets = VP:GetLineAOECastPosition(ts.target, 0.25, 150, 1000, 2500, player)
	if MainTargetHitChance ~= 0 and nTargets > 1 then CastSpell(_R, AOECastPosition.x, AOECastPosition.z) end
	if ts.target.isFleeing and MainTargetHitChance ~= 0 then CastSpell(_R, AOECastPosition.x, AOECastPosition.z) end
	
end

--[[ Helper Functions ]]--
function GetPlayers(team, includeDead, includeSelf, maxDistance)
	local players = {}
	local result = {}
	
	if team == player.team then
		players = GetAllyHeroes()
	else
		players = GetEnemyHeroes()
	end
	
	for i=1, #players, 1 do
		if players[i].visible and (not players[i].dead or players[i].dead == includeDead) and player:GetDistance(players[i]) < maxDistance then
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

function buy()
	if InFountain() or player.dead then	
		-- Item purchases
		if GetTickCount() > lastBuy + buyDelay then
			if GetInventorySlotItem(shopList[nextbuyIndex]) ~= nil then
				--Last Buy successful
				nextbuyIndex = nextbuyIndex + 1
			else
				lastBuy = GetTickCount()
				BuyItem(shopList[nextbuyIndex])
			end
		end
	end
end

--draws Menu
function drawMenu()
	-- Config Menu
	config = scriptConfig("UnifiedSona", "UnifiedSona")	

	config:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONOFF, true)
	config:addParam("autoBuy", "Auto Buy Items", SCRIPT_PARAM_ONOFF, true)
	config:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_ONOFF, true)

	config:addSubMenu("Auto Heal", "autoHeal")
	config:addSubMenu("Auto Celerity", "autoCelerity")
	config:addSubMenu("Auto Harass", "autoHarass")
	config:addSubMenu("Auto Ult", "autoUlt")
	config:addSubMenu("Farming", "autoFarm")
	
	config.autoFarm:addParam("doFarm", "Allow minion attack", SCRIPT_PARAM_ONOFF, false)
	
	config.autoCelerity:addParam("celerityMinMana", "Celerity Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_MIN_MANA, 1, 100, 0)
	
	config.autoHeal:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoHeal:addParam("healMinMana", "Heal Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_MIN_MANA, 1, 100, 0)
	config.autoHeal:addParam("healThreshold", "Heal Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_THRESHOLD, 1, 100, 0)

	config.autoHarass:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	config.autoHarass:addParam("harassTowerDive", "Harass Under Towers", SCRIPT_PARAM_ONOFF, false)
	config.autoHarass:addParam("harassMinMana", "Harass Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HARASS_MIN_MANA, 1, 100, 0)

	config.autoUlt:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)	
end

function isMyAutoAttack(unit, spell)
	return (unit.name == player.name and spell.name:lower():find("attack") ~= nil)
end

function getManaPercent(unit)
	local obj = unit or player
	return (obj.mana / obj.maxMana) * 100
end

function getHealthPercent(unit)
	local obj = unit or player
	return (obj.health / obj.maxHealth) * 100
end

function OnProcessSpell(unit,spell)
	if config.autoFarm.doFarm and isMyAutoAttack(unit, spell) then 
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end 
	elseif isMyAutoAttack(unit, spell) then
		if(spell.target.name:lower():find("minion")~=nil) then player:HoldPosition() end
	end
end

-- obCreatObj
function OnCreateObj(obj)
	-- Check if player is recalling and set isrecalling
	if obj.name:find("TeleportHome") then
		if GetDistance(player, obj) <= 70 then
			isRecalling = true
		end
	end
end

-- OnDeleteObj
function OnDeleteObj(obj)
	if obj.name:find("TeleportHome") then
		-- Set isRecalling off after short delay to prevent using abilities once at base
		DelayAction(function() isRecalling = false end, RECALL_DELAY)
	end
end

function _OrbWalk()
	myTarget = ts.target
	if myTarget == nil then return end
	if GetDistance(myTarget) <= myTrueRange and timeToShoot() then		
		myHero:Attack(myTarget)
	end
end

function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end 

--[[ OnTick ]]--
function OnTick()
	-- Check if script should be run
	--if not config.enableScript then return end
	
	--target update
	ts:update()
	_OrbWalk()
	
	-- Auto Level
	if config.autoLevel and player.level > GetHeroLeveled() then
		
		LevelSpell(levelSequence[GetHeroLeveled() + 1])
	end

	-- Recall Check
	if (isRecalling) then
		return -- Don't perform recall canceling actions
	end

	buy()

	-- Only perform following tasks if not in fountain 
	if not InFountain() then
		Behavior()
	end
end

function OnLoad()
	player = GetMyHero()
	drawMenu()
	startingTime = GetTickCount()
	
	VP = VPrediction()
	myTrueRange = myHero.range + GetDistance(myHero.minBBox)
	
	if AutoUpdate then
		Update()
	end
end
