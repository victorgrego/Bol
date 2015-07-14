local version = "1.04"
--[[

--]]

-- Champion Check
require 'VPrediction'

if myHero.charName ~= "Sona" then return end

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
lastBoughtItem = nil
UP_TO_DATE = true
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
	if enemies ~= nil and #enemies > 0 and getManaPercent() > Menu.autoHarass.harassMinMana and player:CanUseSpell(_Q) == READY then
		CastSpell(_Q)
	end
	
	--autoW
	if friends ~= nil and #friends > 0 and getManaPercent() > Menu.autoHeal.healMinMana and player:CanUseSpell(_W) == READY then
		for i = 1, #friends, 1 do
			if getHealthPercent(friends[i]) < Menu.autoHeal.healThreshold then
				CastSpell(_W)
				break
			end
		end
	end
	
	--autoE
	if friends ~= nil and #friends > 0 and player:CanUseSpell(_E) == READY and getManaPercent() > Menu.autoCelerity.celerityMinMana then
		for i = 1, #Efriends, 1 do
			if Efriends[i].isFleeing then
				CastSpell(_E)
				break
			end
		end
	end
	
	if ts.target == nil or not Menu.autoUlt.enabled then return end
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

local IDBytes = {
	[0x00] = 0x10, [0x01] = 0xC5, [0x02] = 0x0C, [0x03] = 0x9F, [0x04] = 0x9C, [0x05] = 0x75, [0x06] = 0xE5, [0x07] = 0x09, [0x08] = 0xC2, [0x09] = 0x43, [0x0A] = 0x97, [0x0B] = 0xB2, 
	[0x0C] = 0xA9, [0x0D] = 0x9A, [0x0E] = 0x0F, [0x0F] = 0x57, [0x10] = 0x54, [0x11] = 0x51, [0x12] = 0x01, [0x13] = 0x8A, [0x14] = 0x1B, [0x15] = 0xC8, [0x16] = 0xD3, [0x17] = 0x58, 
	[0x18] = 0x50, [0x19] = 0x23, [0x1A] = 0x4F, [0x1B] = 0xFF, [0x1C] = 0x95, [0x1D] = 0x84, [0x1E] = 0xA1, [0x1F] = 0x8C, [0x20] = 0x69, [0x21] = 0x30, [0x22] = 0xA8, [0x23] = 0xEF, 
	[0x24] = 0xBF, [0x25] = 0xFC, [0x26] = 0x59, [0x27] = 0x4E, [0x28] = 0x39, [0x29] = 0x5D, [0x2A] = 0x1F, [0x2B] = 0xE8, [0x2C] = 0xB7, [0x2D] = 0xAE, [0x2E] = 0xAC, [0x2F] = 0x9E, 
	[0x30] = 0xF8, [0x31] = 0xE0, [0x32] = 0x62, [0x33] = 0xA0, [0x34] = 0xC7, [0x35] = 0xD4, [0x36] = 0xBD, [0x37] = 0x0D, [0x38] = 0x5F, [0x39] = 0xE3, [0x3A] = 0x2E, [0x3B] = 0xD5, 
	[0x3C] = 0xCE, [0x3D] = 0x6D, [0x3E] = 0x81, [0x3F] = 0x63, [0x40] = 0xC0, [0x41] = 0xCF, [0x42] = 0x40, [0x43] = 0x1C, [0x44] = 0xB8, [0x45] = 0x3B, [0x46] = 0xD9, [0x47] = 0x94, 
	[0x48] = 0xBA, [0x49] = 0x88, [0x4A] = 0xC6, [0x4B] = 0x27, [0x4C] = 0x48, [0x4D] = 0x3E, [0x4E] = 0x1E, [0x4F] = 0xD0, [0x50] = 0x15, [0x51] = 0x7E, [0x52] = 0x08, [0x53] = 0x7C, 
	[0x54] = 0x70, [0x55] = 0x04, [0x56] = 0x41, [0x57] = 0xB1, [0x58] = 0xA6, [0x59] = 0xD1, [0x5A] = 0x4D, [0x5B] = 0xC3, [0x5C] = 0x05, [0x5D] = 0x90, [0x5E] = 0xC4, [0x5F] = 0x98, 
	[0x60] = 0xFE, [0x61] = 0x35, [0x62] = 0xED, [0x63] = 0xA5, [0x64] = 0xC9, [0x65] = 0x85, [0x66] = 0xF9, [0x67] = 0x74, [0x68] = 0x96, [0x69] = 0x8D, [0x6A] = 0xBC, [0x6B] = 0xFA, 
	[0x6C] = 0x31, [0x6D] = 0x11, [0x6E] = 0x5B, [0x6F] = 0xAD, [0x70] = 0x4C, [0x71] = 0xA2, [0x72] = 0xB3, [0x73] = 0xEE, [0x74] = 0xE6, [0x75] = 0xD8, [0x76] = 0x02, [0x77] = 0x3C, 
	[0x78] = 0x8B, [0x79] = 0xE2, [0x7A] = 0x7A, [0x7B] = 0xDD, [0x7C] = 0x4A, [0x7D] = 0x00, [0x7E] = 0x6A, [0x7F] = 0xE9, [0x80] = 0x7B, [0x81] = 0xF6, [0x82] = 0x89, [0x83] = 0x2C, 
	[0x84] = 0xEB, [0x85] = 0xCA, [0x86] = 0x6C, [0x87] = 0x2A, [0x88] = 0xDB, [0x89] = 0xE7, [0x8A] = 0xAF, [0x8B] = 0x4B, [0x8C] = 0x0E, [0x8D] = 0x16, [0x8E] = 0x2F, [0x8F] = 0x76, 
	[0x90] = 0x91, [0x91] = 0xF1, [0x92] = 0x92, [0x93] = 0x66, [0x94] = 0x44, [0x95] = 0xAA, [0x96] = 0x72, [0x97] = 0xF7, [0x98] = 0xF4, [0x99] = 0x93, [0x9A] = 0x2D, [0x9B] = 0x80, 
	[0x9C] = 0x03, [0x9D] = 0x65, [0x9E] = 0x42, [0x9F] = 0xF2, [0xA0] = 0x18, [0xA1] = 0xCC, [0xA2] = 0x8E, [0xA3] = 0x99, [0xA4] = 0x14, [0xA5] = 0x7D, [0xA6] = 0xC1, [0xA7] = 0xD2, 
	[0xA8] = 0x5E, [0xA9] = 0x33, [0xAA] = 0x64, [0xAB] = 0x3F, [0xAC] = 0x38, [0xAD] = 0x0A, [0xAE] = 0xD6, [0xAF] = 0xD7, [0xB0] = 0x6E, [0xB1] = 0xF3, [0xB2] = 0x1A, [0xB3] = 0xE4, 
	[0xB4] = 0x68, [0xB5] = 0x13, [0xB6] = 0x46, [0xB7] = 0xB0, [0xB8] = 0x73, [0xB9] = 0x12, [0xBA] = 0x06, [0xBB] = 0x5C, [0xBC] = 0x37, [0xBD] = 0x86, [0xBE] = 0x61, [0xBF] = 0x78, 
	[0xC0] = 0xB9, [0xC1] = 0xF0, [0xC2] = 0x21, [0xC3] = 0xBE, [0xC4] = 0x24, [0xC5] = 0xEA, [0xC6] = 0x32, [0xC7] = 0xDE, [0xC8] = 0xDA, [0xC9] = 0x8F, [0xCA] = 0x47, [0xCB] = 0x1D, 
	[0xCC] = 0xDF, [0xCD] = 0xBB, [0xCE] = 0x3D, [0xCF] = 0xE1, [0xD0] = 0x6F, [0xD1] = 0xA3, [0xD2] = 0x55, [0xD3] = 0xAB, [0xD4] = 0x83, [0xD5] = 0x17, [0xD6] = 0x7F, [0xD7] = 0x2B, 
	[0xD8] = 0x34, [0xD9] = 0x52, [0xDA] = 0x87, [0xDB] = 0xB6, [0xDC] = 0x45, [0xDD] = 0xFD, [0xDE] = 0x28, [0xDF] = 0xB4, [0xE0] = 0x26, [0xE1] = 0xCB, [0xE2] = 0xA4, [0xE3] = 0xA7, 
	[0xE4] = 0xF5, [0xE5] = 0xCD, [0xE6] = 0x77, [0xE7] = 0xDC, [0xE8] = 0x22, [0xE9] = 0x6B, [0xEA] = 0xEC, [0xEB] = 0x49, [0xEC] = 0x29, [0xED] = 0x9D, [0xEE] = 0x79, [0xEF] = 0x67, 
	[0xF0] = 0x3A, [0xF1] = 0x82, [0xF2] = 0x5A, [0xF3] = 0x9B, [0xF4] = 0xB5, [0xF5] = 0x0B, [0xF6] = 0x56, [0xF7] = 0x71, [0xF8] = 0x19, [0xF9] = 0x25, [0xFA] = 0x07, [0xFB] = 0xFB, 
	[0xFC] = 0x20, [0xFD] = 0x60, [0xFE] = 0x36, [0xFF] = 0x53,
}

function OnRecvPacket(p)
	if VIP_USER and UP_TO_DATE then
		if p.header == 0x005C then
			p.pos=2
			if p:DecodeF() == myHero.networkID then
				p.pos=12
				local bytes = {}
				for i=4, 1, -1 do
					bytes[i] = IDBytes[p:Decode1()]
				end
				lastBoughtItem = bit32.bxor(bit32.lshift(bit32.band(bytes[1],0xFF),24),bit32.lshift(bit32.band(bytes[2],0xFF),16),bit32.lshift(bit32.band(bytes[3],0xFF),8),bit32.band(bytes[4],0xFF))
			end
		end
	end
end

function BuyItem1(id)
	local rB = {}
	for i=0, 255 do rB[IDBytes[i]] = i end
	local p = CLoLPacket(0x0008)
	p.vTable = 0xEAC648
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
				if VIP_USER and UP_TO_DATE then BuyItem1(shopList[nextbuyIndex])
				else BuyItem(shopList[nextbuyIndex]) end
			end
		end
	end
end

--draws Menu
function drawMenu()
	-- Config Menu
	Menu = scriptConfig("UnifiedSona", "UnifiedSona")	

	Menu:addSubMenu("Commons", "common")
	
	Menu.common:addParam("enableScript", "Enable Script", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("autoBuy", "Auto Buy Items", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("Auto Heal", "autoHeal")
	Menu:addSubMenu("Auto Celerity", "autoCelerity")
	Menu:addSubMenu("Auto Harass", "autoHarass")
	Menu:addSubMenu("Auto Ult", "autoUlt")
	Menu:addSubMenu("Farming", "autoFarm")
	
	Menu.autoFarm:addParam("doFarm", "Allow minion attack", SCRIPT_PARAM_ONOFF, false)
	
	Menu.autoCelerity:addParam("celerityMinMana", "Celerity Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_MIN_MANA, 1, 100, 0)
	
	Menu.autoHeal:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoHeal:addParam("healMinMana", "Heal Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_MIN_MANA, 1, 100, 0)
	Menu.autoHeal:addParam("healThreshold", "Heal Threshold (%)", SCRIPT_PARAM_SLICE, DEFAULT_HEAL_THRESHOLD, 1, 100, 0)

	Menu.autoHarass:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	Menu.autoHarass:addParam("harassTowerDive", "Harass Under Towers", SCRIPT_PARAM_ONOFF, false)
	Menu.autoHarass:addParam("harassMinMana", "Harass Minimum Mana (%)", SCRIPT_PARAM_SLICE, DEFAULT_HARASS_MIN_MANA, 1, 100, 0)

	Menu.autoUlt:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)	
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
	if Menu.autoFarm.doFarm and isMyAutoAttack(unit, spell) then 
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
	if Menu.autoLevel and player.level > GetHeroLeveled() then
		
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
	
	--[[if AutoUpdate then
		Update()
	end]]
end
