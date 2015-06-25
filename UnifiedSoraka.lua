local version = "1.51"

require "HPrediction"

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
lastBoughtItem = nil

buyDelay = 100 --default 100

-- Constants (do not change)
local GLOBAL_RANGE = 0
local NO_RESOURCE = 0
local DEFAULT_STARCALL_MODE = 3
local DEFAULT_STARCALL_MIN_MANA = 300 --Starcall will not be cast if mana is below this level
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
	
	local QPos, QHitChance = HPred:GetPredict(sorakaStarcall, TargetSelector.target, myHero);
	
	if Menu.autoStarcall.starcallTowerDive == false and UnderTurret(myHero, true) == true and info ~= nil and (info.hitchance ~=0 or hitchance ~= 0) then return end
	
	--if pro and pos and info.hitchance ~= 0 then 
	--	CastSpell(_Q, pos.x, pos.z)
	if QHitChance >= 2 then
		CastSpell(_Q, QPos.x, QPos.z)
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
	
	local EPos, EHitChance = HPred:GetPredict(sorakaEquinox, TargetSelector.target, myHero);
	
	--pos, hitchance = VP:GetPredictedPos(TargetSelector.target, 0.25, 2000, myHero, true)
	
	if Menu.autoStarcall.starcallTowerDive == false and UnderTurret(myHero, true) == true and (hitchance ~= 0) then return end

	if EHitChance >= 2 then
		CastSpell(_E, EPos.x, EPos.z)
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

local IDBytes = {
	[0x00] = 0xFF, [0x01] = 0xDF, [0x02] = 0xFB, [0x03] = 0xDB, [0x04] = 0xF7, [0x05] = 0xD7, [0x06] = 0xF3, [0x07] = 0xD3, [0x08] = 0xFE, [0x09] = 0xDE, [0x0A] = 0xFA, [0x0B] = 0xDA, 
	[0x0C] = 0xF6, [0x0D] = 0xD6, [0x0E] = 0xF2, [0x0F] = 0xD2, [0x10] = 0xFD, [0x11] = 0xDD, [0x12] = 0xF9, [0x13] = 0xD9, [0x14] = 0xF5, [0x15] = 0xD5, [0x16] = 0xF1, [0x17] = 0xD1, 
	[0x18] = 0xFC, [0x19] = 0xDC, [0x1A] = 0xF8, [0x1B] = 0xD8, [0x1C] = 0xF4, [0x1D] = 0xD4, [0x1E] = 0xF0, [0x1F] = 0xD0, [0x20] = 0xBF, [0x21] = 0x9F, [0x22] = 0xBB, [0x23] = 0x9B, 
	[0x24] = 0xB7, [0x25] = 0x97, [0x26] = 0xB3, [0x27] = 0x93, [0x28] = 0xBE, [0x29] = 0x9E, [0x2A] = 0xBA, [0x2B] = 0x9A, [0x2C] = 0xB6, [0x2D] = 0x96, [0x2E] = 0xB2, [0x2F] = 0x92, 
	[0x30] = 0xBD, [0x31] = 0x9D, [0x32] = 0xB9, [0x33] = 0x99, [0x34] = 0xB5, [0x35] = 0x95, [0x36] = 0xB1, [0x37] = 0x91, [0x38] = 0xBC, [0x39] = 0x9C, [0x3A] = 0xB8, [0x3B] = 0x98, 
	[0x3C] = 0xB4, [0x3D] = 0x94, [0x3E] = 0xB0, [0x3F] = 0x90, [0x40] = 0x7F, [0x41] = 0x5F, [0x42] = 0x7B, [0x43] = 0x5B, [0x44] = 0x77, [0x45] = 0x57, [0x46] = 0x73, [0x47] = 0x53, 
	[0x48] = 0x7E, [0x49] = 0x5E, [0x4A] = 0x7A, [0x4B] = 0x5A, [0x4C] = 0x76, [0x4D] = 0x56, [0x4E] = 0x72, [0x4F] = 0x52, [0x50] = 0x7D, [0x51] = 0x5D, [0x52] = 0x79, [0x53] = 0x59, 
	[0x54] = 0x75, [0x55] = 0x55, [0x56] = 0x71, [0x57] = 0x51, [0x58] = 0x7C, [0x59] = 0x5C, [0x5A] = 0x78, [0x5B] = 0x58, [0x5C] = 0x74, [0x5D] = 0x54, [0x5E] = 0x70, [0x5F] = 0x50, 
	[0x60] = 0x3F, [0x61] = 0x1F, [0x62] = 0x3B, [0x63] = 0x1B, [0x64] = 0x37, [0x65] = 0x17, [0x66] = 0x33, [0x67] = 0x13, [0x68] = 0x3E, [0x69] = 0x1E, [0x6A] = 0x3A, [0x6B] = 0x1A, 
	[0x6C] = 0x36, [0x6D] = 0x16, [0x6E] = 0x32, [0x6F] = 0x12, [0x70] = 0x3D, [0x71] = 0x1D, [0x72] = 0x39, [0x73] = 0x19, [0x74] = 0x35, [0x75] = 0x15, [0x76] = 0x31, [0x77] = 0x11, 
	[0x78] = 0x3C, [0x79] = 0x1C, [0x7A] = 0x38, [0x7B] = 0x18, [0x7C] = 0x34, [0x7D] = 0x14, [0x7E] = 0x30, [0x7F] = 0x10, [0x80] = 0xEF, [0x81] = 0xCF, [0x82] = 0xEB, [0x83] = 0xCB, 
	[0x84] = 0xE7, [0x85] = 0xC7, [0x86] = 0xE3, [0x87] = 0xC3, [0x88] = 0xEE, [0x89] = 0xCE, [0x8A] = 0xEA, [0x8B] = 0xCA, [0x8C] = 0xE6, [0x8D] = 0xC6, [0x8E] = 0xE2, [0x8F] = 0xC2, 
	[0x90] = 0xED, [0x91] = 0xCD, [0x92] = 0xE9, [0x93] = 0xC9, [0x94] = 0xE5, [0x95] = 0xC5, [0x96] = 0xE1, [0x97] = 0xC1, [0x98] = 0xEC, [0x99] = 0xCC, [0x9A] = 0xE8, [0x9B] = 0xC8, 
	[0x9C] = 0xE4, [0x9D] = 0xC4, [0x9E] = 0xE0, [0x9F] = 0xC0, [0xA0] = 0xAF, [0xA1] = 0x8F, [0xA2] = 0xAB, [0xA3] = 0x8B, [0xA4] = 0xA7, [0xA5] = 0x87, [0xA6] = 0xA3, [0xA7] = 0x83, 
	[0xA8] = 0xAE, [0xA9] = 0x8E, [0xAA] = 0xAA, [0xAB] = 0x8A, [0xAC] = 0xA6, [0xAD] = 0x86, [0xAE] = 0xA2, [0xAF] = 0x82, [0xB0] = 0xAD, [0xB1] = 0x8D, [0xB2] = 0xA9, [0xB3] = 0x89, 
	[0xB4] = 0xA5, [0xB5] = 0x85, [0xB6] = 0xA1, [0xB7] = 0x81, [0xB8] = 0xAC, [0xB9] = 0x8C, [0xBA] = 0xA8, [0xBB] = 0x88, [0xBC] = 0xA4, [0xBD] = 0x84, [0xBE] = 0xA0, [0xBF] = 0x80, 
	[0xC0] = 0x6F, [0xC1] = 0x4F, [0xC2] = 0x6B, [0xC3] = 0x4B, [0xC4] = 0x67, [0xC5] = 0x47, [0xC6] = 0x63, [0xC7] = 0x43, [0xC8] = 0x6E, [0xC9] = 0x4E, [0xCA] = 0x6A, [0xCB] = 0x4A, 
	[0xCC] = 0x66, [0xCD] = 0x46, [0xCE] = 0x62, [0xCF] = 0x42, [0xD0] = 0x6D, [0xD1] = 0x4D, [0xD2] = 0x69, [0xD3] = 0x49, [0xD4] = 0x65, [0xD5] = 0x45, [0xD6] = 0x61, [0xD7] = 0x41, 
	[0xD8] = 0x6C, [0xD9] = 0x4C, [0xDA] = 0x68, [0xDB] = 0x48, [0xDC] = 0x64, [0xDD] = 0x44, [0xDE] = 0x60, [0xDF] = 0x40, [0xE0] = 0x2F, [0xE1] = 0x0F, [0xE2] = 0x2B, [0xE3] = 0x0B, 
	[0xE4] = 0x27, [0xE5] = 0x07, [0xE6] = 0x23, [0xE7] = 0x03, [0xE8] = 0x2E, [0xE9] = 0x0E, [0xEA] = 0x2A, [0xEB] = 0x0A, [0xEC] = 0x26, [0xED] = 0x06, [0xEE] = 0x22, [0xEF] = 0x02, 
	[0xF0] = 0x2D, [0xF1] = 0x0D, [0xF2] = 0x29, [0xF3] = 0x09, [0xF4] = 0x25, [0xF5] = 0x05, [0xF6] = 0x21, [0xF7] = 0x01, [0xF8] = 0x2C, [0xF9] = 0x0C, [0xFA] = 0x28, [0xFB] = 0x08, 
	[0xFC] = 0x24, [0xFD] = 0x04, [0xFE] = 0x20, [0xFF] = 0x00,
}

function OnRecvPacket(p)
	if p.header == 0x0085 then
		p.pos=2
		if p:DecodeF() == myHero.networkID then
			p.pos=10
			local bytes = {}
			for i=4, 1, -1 do
				bytes[i] = IDBytes[p:Decode1()]
			end
			lastBoughtItem = bit32.bxor(bit32.lshift(bit32.band(bytes[1],0xFF),24),bit32.lshift(bit32.band(bytes[2],0xFF),16),bit32.lshift(bit32.band(bytes[3],0xFF),8),bit32.band(bytes[4],0xFF))
		end
	end
end

function BuyItem1(id)
	local rB = {}
	for i=0, 255 do rB[IDBytes[i]] = i end
	local p = CLoLPacket(0x0042)
	p.vTable = 0xE810FC
	p:EncodeF(myHero.networkID)
	local b1 = bit32.lshift(bit32.band(rB[bit32.band(bit32.rshift(bit32.band(id,0xFFFF),24),0xFF)],0xFF),24)
	local b2 = bit32.lshift(bit32.band(rB[bit32.band(bit32.rshift(bit32.band(id,0xFFFFFF),16),0xFF)],0xFF),16)
	local b3 = bit32.lshift(bit32.band(rB[bit32.band(bit32.rshift(bit32.band(id,0xFFFFFFFF),8),0xFF)],0xFF),8)
	local b4 = bit32.band(rB[bit32.band(id ,0xFF)],0xFF)
	p:Encode4(bit32.bxor(b1,b2,b3,b4))
	p:Encode4(0xE1240DFD)
	SendPacket(p)
end

function buy()
	if InFountain() or myHero.dead then
			-- Item purchases
		if GetTickCount() > lastBuy + buyDelay then
			if lastBoughtItem == shopList[nextbuyIndex] then
				--Last Buy successful
				nextbuyIndex = nextbuyIndex + 1
			else
				lastBuy = GetTickCount()
				BuyItem1(shopList[nextbuyIndex])
				
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
	Menu.autoHeal:addParam("healMinMana", "Starcall Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_STARCALL_MIN_MANA, 0, 100, 0)
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

	
	HPred = HPrediction()
	predictionCD = 200
	predict = true;
	--sorakaStarcall = CircleSS(2000,STARCALL_RANGE, 300, 0.25, true);
	--sorakaEquinox = CircleSS(20000,EQUINOX_RANGE, 300, 0.25, true);
	
	sorakaStarcall = HPSkillshot({type = "PromptCircle", delay = 0.25, range = STARCALL_RANGE, radius = 300, speed = 1200})
	sorakaEquinox = HPSkillshot({type = "PromptCircle", delay = 0, range = EQUINOX_RANGE, radius = 300, speed = 2000})
	
	--[[if AutoUpdate then
		Update()
	end]]
end
