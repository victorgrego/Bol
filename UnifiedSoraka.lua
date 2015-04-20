local version = "1.35"

require "VPrediction"

--[[
UnifiedSoraka by VictorGrego

Features:
- Auto Level Abilities
- Auto Starcall (Q)
- Auto Heal (W)
- Auto Equinox (E)
- Auto Ult [M]
- Avoid hitting enemy under turret
- Auto Buy items

Changelog:
--]]

-- Champion Check
if myHero.charName ~= "Soraka" then return end

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

nextbuyIndex = 1
lastBuy = 0

buyDelay = 100 --default 100

--UPDATE SETTINGS
local AutoUpdate = true
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/victorgrego/Bol/master/UnifiedSoraka.lua?"..math.random(100)
local UPDATE_TMP_FILE = LIB_PATH.."UNSTmp.txt"
local versionmessage = "<font color=\"#81BEF7\" >Changelog: Added autobuy option and changed build to spam skills</font>"

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
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#00FF00\">Successfully updated to: v"..Version..". Please reload the script with F9.</font>")
			else
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#FF0000\">Error updating to new version (v"..Version..")</font>")
			end
			elseif (Version ~= nil) and (Version == tonumber(version)) then
				PrintChat("<font color=\"#81BEF7\" >UnifiedSoraka:</font> <font color=\"#00FF00\">No updates found, latest version: v"..Version.." </font>")
			end
		end
	end
end
-- Constants (do not change)
local GLOBAL_RANGE = 0
local NO_RESOURCE = 0
local DEFAULT_STARCALL_MODE = 3
local DEFAULT_STARCALL_MIN_MANA = 50 --Starcall will not be cast if mana is below this level
local DEFAULT_NUM_HIT_MINIONS = 3 -- number of minions that need to be hit by starcall before its cast
local DEFAULT_HEAL_MODE = 2
local DEFAULT_HEAL_THRESHOLD = 75 -- for healMode 3, default 75 (75%)
local DEFAULT_INFUSE_MODE = 2 
local DEFAULT_MIN_ALLY_SILENCE = 70 -- percentage of mana nearby ally lolshould have before soraka uses silence
local DEFAULT_ULT_MODE = 2
local DEFAULT_ULT_THRESHOLD = 35 --percentage of hp soraka/ally/team must be at or missing for ult, eg 10 (10%)
local DEFAULT_DENY_THRESHOLD = 75
local DEFAULT_STEAL_THRESHOLD = 60
local MAX_PLAYER_AA_RANGE = 850
local HEAL_DISTANCE = 700
local HL_slot = nil
local CL_slot = nil
local DEFAULT_MANA_CLARITY = 50

-- Recall Check
local isRecalling = false
local RECALL_DELAY = 0.5

-- Auto Level
local levelSequence = {_W,_E,_Q,_W,_W,_R,_W,_E,_W,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q}

--Target Selector
--ts = TargetSelector(TARGET_LOW_HP, 1000, DAMAGE_MAGIC, true)

-- Auto Heal (W) - Soraka heals the nearest injured ally champion
local RAW_HEAL_AMOUNT = {110, 140, 170, 200, 230}
local RAW_HEAL_RATIO = 0.6
local HEAL_RANGE = 450
local HEAL_MIN_HP = 0.05

--Auto StarCall (Q)
local STARCALL_RANGE = 950

local EQUINOX_RANGE = 925

--[[ ultMode notes:
1 = ult when Soraka is low/about to die, under ultThreshold% of hp [selfish ult]
2 = ult when ally is low/about to die, under ultThreshold% of hp [lane partner ult]
3 = ult when total missing health of entire team exceeds ultThreshold (ie 50% of entire team health is missing)
-]]

--[[ Main Functions ]]--

-- Soraka performs starcall to help push/farm a lane or harrass enemy champions (or both)
function doSorakaStarcall()
	TargetSelector:update()
	if not TargetSelector.target then return end   
	local pos, info, hitchance
	local pro = false;
	
	--[[if VIP_USER then
		pos, info = Prodiction.GetPrediction(ts.target, STARCALL_RANGE, nil, 0.25, 125, nil)
		pro = true
	else]]
	pos, hitchance = VP:GetPredictedPos(TargetSelector.target, 0.25, 2000, myHero, true)
	--end
	
	if Menu.autoStarcall.starcallTowerDive == false and UnderTurret(myHero, true) == true and info ~= nil and (info.hitchance ~=0 or hitchance ~= 0) then return end
	
	--if pro and pos and info.hitchance ~= 0 then 
	--	CastSpell(_Q, pos.x, pos.z)
	if hitchance ~= 0 then
		CastSpell(_Q, pos.x, pos.z)
	end
end

-- Soraka Heals the nearby most injured ally or herself, assumes heal is ready to be used
function doSorakaHeal()
	-- Find ally champion to heal
	local ally = GetPlayer(myHero.team, false, false, myHero, HEAL_RANGE, "health")
	--if ally ~= nil then PrintChat("Ally Champion: "..ally.name) end
	-- If no eligible ally, return
	
	-- Heal ally
	if ally ~= nil and (ally.health/ally.maxHealth) < Menu.autoHeal.healThreshold/100 then
		CastSpell(_W, ally)
	end
end

-- Soraka uses ultimate based on user preference
function doSorakaUlt()
	-- Ult based on ultMode
	if Menu.autoUlt.ultMode == 1 then
		if (myHero.health/myHero.maxHealth) < (Menu.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	elseif Menu.autoUlt.ultMode == 2 then
		-- Find nearby ally champion (your lane partner usually) that is fatally injured

		local ally = GetPlayer(myHero.team, false, true, nil, GLOBAL_RANGE, "health")

		-- Use ult if suitable ally found
		if ally ~= nil and (ally.health/ally.maxHealth) < (Menu.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	elseif Menu.autoUlt.ultMode == 3 then
		--find total hp of team as a percentage, ie team had 40% of their max hp
		local totalMissingHP = 0
		local counter = 0

		for i=1, heroManager.iCount do
			local hero = heroManager:GetHero(i)

			if hero ~= nil and hero.type == "AIHeroClient" and hero.team == myHero.team and hero.dead == false then --checks for ally and that person is not dead
				totalMissingHP = totalMissingHP + (hero.health/hero.maxHealth)
				counter = counter + 1
			end
		end

		totalMissingHP = totalMissingHP / counter

		if totalMissingHP < (Menu.autoUlt.ultThreshold / 100) then
			CastSpell(_R)
		end
	end
end

-- Soraka Infuses the most mana deprived ally donating them mana
function doSorakaEquinox()
	TargetSelector:update()
	if not TargetSelector.target then return end  
	local pos, info, hitchance
	local pro = false;

	pos, hitchance = VP:GetPredictedPos(TargetSelector.target, 0.25, 2000, myHero, true)
	
	if Menu.autoStarcall.starcallTowerDive == false and UnderTurret(myHero, true) == true and (hitchance ~= 0) then return end

	if hitchance ~= 0 then
		CastSpell(_E, pos.x, pos.z)
	end
end

--[[ Helper Functions ]]--


--[[ Helper Functions ]]--
-- Return player based on their resource or stat
function GetPlayer(team, includeDead, includeSelf, distanceTo, distanceAmount, resource)
	local target = nil

	for i=1, heroManager.iCount do
		local member = heroManager:GetHero(i)

		if member ~= nil and member.type == "AIHeroClient" and member.team == team and (member.dead ~= true or includeDead) then
			if member.charName ~= myHero.charName or includeSelf then
				if distanceAmount == GLOBAL_RANGE or member:GetDistance(distanceTo) <= distanceAmount then
					if target == nil then target = member end

					if resource == "health" then --least health
						if member.health < target.health then target = member end
					elseif resource == "mana" then --least mana
						if member.mana < target.mana then target = member end
					elseif resource == "AD" then --highest AD
						if member.totalDamage > target.totalDamage then target = member end
					elseif resource == NO_RESOURCE then
						return member -- as any member is eligible
					end
				end
			end
		end
	end

	return target
end

function buy()
	if InFountain() or myHero.dead then
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
	Menu = scriptConfig("UnifiedSoraka", "UnifiedSorakaa")	

	Menu:addSubMenu("Common Options", "common");
	
	Menu.common:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("autoBuy", "Auto Buy Items", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_ONOFF, true)
	
	
	Menu:addSubMenu("Auto Heal", "autoHeal")
	Menu:addSubMenu("Auto Starcall", "autoStarcall")
	Menu:addSubMenu("Auto Equinox", "autoEquinox")
	Menu:addSubMenu("Auto Ult", "autoUlt")
	Menu:addSubMenu("Farming", "autoFarm")

	Menu.autoFarm:addParam("doFarm", "Allow minion attack", SCRIPT_PARAM_ONOFF, false)

	Menu.autoHeal:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoHeal:addParam("healThreshold", "Heal Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_THRESHOLD, 0, 100, 0)
	Menu.autoHeal:addParam("healMinMana", "Heal Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_STARCALL_MIN_MANA, 0, 100, 0)
	Menu.autoHeal:addParam("sorakaThreshold", "Soraka HP Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_THRESHOLD, 5, 100, 0)

	Menu.autoStarcall:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoStarcall:addParam("starcallTowerDive", "Starcall Under Towers", SCRIPT_PARAM_ONOFF, false)
	Menu.autoStarcall:addParam("starcallMinMana", "Starcall Minimum Mana", SCRIPT_PARAM_SLICE, DEFAULT_STARCALL_MIN_MANA, 0, 100, 0)

	Menu.autoEquinox:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoEquinox:addParam("equinoxMinMana", "Equinox Min Mana", SCRIPT_PARAM_SLICE, DEFAULT_STARCALL_MIN_MANA, 0, 100, 0)
	Menu.autoEquinox:addParam("equinoxTowerDive", "Equinox Under Towers", SCRIPT_PARAM_ONOFF, false)

	Menu.autoUlt:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoUlt:addParam("ultMode", "Ultimate Mode", SCRIPT_PARAM_LIST, DEFAULT_ULT_MODE, { "Selfish", "Lane Partner", "Entire Team" })
	Menu.autoUlt:addParam("ultThreshold", "Ult Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_ULT_THRESHOLD, 0, 100, 0)
	
	TargetSelector = TargetSelector(TARGET_LOW_HP, 1000, DAMAGE_MAGIC, true)
	TargetSelector.name = "Soraka"
	Menu:addTS(TargetSelector)
end

function OnProcessSpell(unit,spell)
	if not Menu.autoFarm.doFarm  and unit.name == myHero.name and spell.name:lower():find("attack") ~= nil then
		if(spell.target.name:lower():find("minion")~=nil) then myHero:HoldPosition() end
	end
end

-- obCreatObj
function OnCreateObj(obj)
	-- Check if player is recalling and set isrecalling
	if GetDistance(myHero, obj) < 50 and obj.name:lower():find("teleporthome") then
		isRecalling = true
	end
end

-- OnDeleteObj
function OnDeleteObj(obj)
	if GetDistance(myHero, obj) < 50 and obj.name:lower():find("teleporthome") then
		-- Set isRecalling off after short delay to prevent using abilities once at base
		DelayAction(function() isRecalling = false end, RECALL_DELAY)
	end
end

--[[ OnTick ]]--
function OnTick()
	-- Check if script should be run
	--if not Menu.common.enableScript then return end
	if (isRecalling) then
		return -- Don't perform recall canceling actions
	end
	
	-- Auto Level
	if Menu.common.autoLevel and myHero.level > GetHeroLeveled() then
		LevelSpell(levelSequence[GetHeroLeveled() + 1])
	end
	
	-- Auto Ult (R)
	if Menu.autoUlt.enabled and myHero:CanUseSpell(_R) == READY then
		doSorakaUlt()
	end

	if Menu.common.autoBuy then buy() end 
	
	-- Only perform following tasks if not in fountain 
	if not InFountain() then
		-- Auto Heal and Deny Farm (W)
		if myHero:CanUseSpell(_W) == READY and Menu.autoHeal.enabled  and (myHero.mana/myHero.maxMana) > Menu.autoHeal.healMinMana / 100  and myHero.health/myHero.maxHealth > Menu.autoHeal.sorakaThreshold/100 then
			doSorakaHeal()
		end
		
		--Auto Equinox (E)
		if myHero:CanUseSpell(_E) == READY and Menu.autoEquinox.enabled and myHero.mana/myHero.maxMana > Menu.autoEquinox.equinoxMinMana/100 then
			doSorakaEquinox()
		end

		-- Auto StarCall (Q)
		if Menu.autoStarcall.enabled and myHero:CanUseSpell(_Q) == READY and myHero.mana/myHero.maxMana  > Menu.autoStarcall.starcallMinMana/100 then
			doSorakaStarcall()
		end
	end
end

function OnLoad()
	drawMenu()
	startingTime = GetTickCount()
	
	nextbuyIndex = 1
	lastBuy = 0

	
	VP = VPrediction()
	
	--[[if AutoUpdate then
		Update()
	end]]
end
