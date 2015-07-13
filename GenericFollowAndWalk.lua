local version = "1.4"
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
preferences = {FOLLOW_PARTNER = 0, GO_BASE = 0}



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

	AFK_MAXTIME = 60
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
	
	--Behavior tree root
	root = nil

	detectSpawnPoints()
end

--Classes Area

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
		if GetDistance(partner,player) <= config.followChamp.followDist then return true
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
			if friends[i] ~= nil and GetDistance(friends[i], player) < GetDistance(closest,player) then closest = friends[i] end
		end
		
		if closest ~= nil and GetDistance(closest, player) <= config.followChamp.followDist then return true
		else return false
		end
	end
	
	actions["inTurret"] = function()
		local myTurret = GetCloseTower(player, player.team)
		if GetDistance(myTurret, player) <= config.followChamp.followDist and GetDistance(allySpawn, player) < GetDistance(allySpawn, myTurret) then return true
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
			if obj ~= nil and obj.valid and GetDistance(myHero, obj) < 50 and obj.name:lower():find("teleporthome") then
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
		if(GetDistance(Vector(followX, followZ), player) < 30) then return true end
		return false
	end
	
	actions["towerFocusPlayer"] = function()
		if FocusOfTower and GetDistance(yikesTurret, player) > 1000 then FocusOfTower = false end
	
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
function PRecall()
	local p = CLoLPacket(0x0050)
	p.vTable = 0xE73EF8
	p:EncodeF(myHero.networkID)
	p:Encode4(0xF891B9F5)
	p:Encode2(0xB4B1)
	p:Encode2(0x0000)
	p:Encode2(0xFDB1)
	p:Encode2(0x0000)
	p:Encode1(0xEE)
	p:Encode1(0x6D)
	p:Encode2(0x3D3D)
	p:Encode1(0x3C)
	p:Encode4(0x95959595)
	p:Encode4(0x95959595)
	p:Encode1(0xF5)
	p:Encode1(0xDC)
	p:Encode2(0xE924)
	p:Encode2(0x0000)
	SendPacket(p)
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

function OnDeleteObj(object)
	if GetDistance(myHero, object) < 50 and object.name:lower():find("teleporthome") then
		DelayAction(function() 
		pRecalling = false 
		end, 0.5, {0})
	end
end

function OnCreateObj(object)
	if GetDistance(myHero, object) < 50 and object.name:lower():find("teleporthome") then
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

adviceStringsPT = {
EEscapeAdvice = {"Usa o W para fugir!", "Foge com o W", "O W te ajuda a fugir", "Usa o W pra trás"},
	heroFocus = {"Cuidado com os bots", "Foge deles!", "Cuidado que eles estão te tando dano."},
	towerFocus = {"Cuidado com a torre!", "A torre está te atacando, cuidado!", "Sai da parte vermelha", "Foge da torre!"},
	minionsFocus = {"Os minions estão te atacando, melhor recuar","Cuidado com os minions", "Os minios vão te matar"},
	healthAdvice = {"Vc está com hp baixo, vai base!", "Melhor vc ir base", "Aperta B e vai base", "Vc ta com pouca vida, melhor ir base", "Se você tiver poção usa, senão melhor ir base"},
	lastHit = {"Tenta acertar o último ataque nos minions.", "Dá o último golpe nos minions que vc vai ganhar ouro"},
	safePosition = {"Joga mais recuado.", "Tenta jogar mais perto da torre"},
	manaAdvice = {"Voce está gastando muita mana", "Tenta economizar mana", "Guarda mana para usar poder nos inimigos"},
 	QFarmAdvice = {"Usa o Q para farmar", "Usa o Q nos minions pra matar", "Se vc usar o Q fica mais facil farmar"}, -- draven, ezreal, urgot
	QHarassAdvice = {"Usa o Q para dar dano nos bots", "Tenta acertar o Q nos inimigos", "Dá Q nos inimigos"}, -- sivir, ezreal, caitlyn, urgot, varus, kalista, kog maw, graves, corki, draven, Quinn, Luzcian, miss fortune
	WEscapeAdvice = {"Usa o W para fugir!", "Foge com o W", "O W te ajuda a fugir", "Usa o W pra trás"}, -- Corki, Draven, Tristana, Caitlyn, Ezreal, Graves, Lucian
	RKillAdvice = {"Usa R pra matar os bots", "Mata ele com o R", "Dá R nele"},
	cheerByKilling = {"Nice!", "GJ", "Massa", "Bom trabalho", "Boa!"}
}

adviceStringTimers = {
	heroFocus = 180, heroFocusL = os.clock(),
	towerFocus = 180, towerFocusL = os.clock(),
	minionsFocus = 180, minionsFocusL = os.clock(),
	healthAdvice = 240, healthAdviceL = os.clock(),
	lastHit = 180, lastHitL = os.clock(),
	safePosition = 180, safePositionL = os.clock(),
	manaAdvice = 600, manaAdviceL = os.clock(),
 	QFarmAdvice = 600, QFarmAdviceL = os.clock(), -- draven, ezreal, urgot
	QHarassAdvice = 600, QHarassAdviceL = os.clock(),-- sivir, ezreal, caitlyn, urgot, varus, kalista, kog maw, graves, corki, draven, Quinn, Luzcian, miss fortune
	WEscapeAdvice = 600, WEscapeAdviceL = os.clock(), -- Corki, Draven, Tristana
	EEscapeAdvice = 600, EEscapeAdviceL = os.clock(), -- Caitlyn, Ezreal, Graves, Lucian
	RKillAdvice = 600, RKillAdviceL = os.clock(),
	cheerByKilling = 300, cheerByKilling = os.clock()
}

--[[
	Implemented:
	Enemy focus
	Enemy tower Focus
	Enemy minions Focus
	
]]

function OnProcessSpell(unit, spell)
	if unit.type == "obj_AI_Turret" and spell.name:lower():find("attack") and spell.target == player then 
		FocusOfTower = true
		yikesTurret = GetCloseTower(player, TEAM_ENEMY)
	end

	if spell.target ~= nil and  unit.team ~= myHero.team and spell.target.name == partner.name then 
		--print("Detected!")
		if unit.type == myHero.type and os.clock() > adviceStringTimers.heroFocusL + adviceStringTimers.heroFocus then
			SendChat(adviceStringsPT.heroFocus[math.floor(math.random(#adviceStringsPT.heroFocus))])
			adviceStringTimers.heroFocusL = os.clock()
		elseif unit.name:lower():find("minion")~=nil and os.clock() > adviceStringTimers.minionsFocusL + adviceStringTimers.minionsFocus then
			SendChat(adviceStringsPT.minionsFocus[math.floor(math.random(#adviceStringsPT.minionsFocus))])
			adviceStringTimers.minionsFocusL = os.clock()
		elseif unit.type == "obj_AI_Turret" and spell.name:lower():find("attack") and os.clock() > adviceStringTimers.towerFocusL + adviceStringTimers.towerFocus then
			SendChat(adviceStringsPT.towerFocus[math.floor(math.random(#adviceStringsPT.towerFocus))])
			adviceStringTimers.towerFocusL = os.clock()
		end
	end
end

function OnTick()

	if #allies < 4 then allies = GetPlayers(player.team, true, false) end

	if(config.enableScript)then
		root:run()
	end
end

function OnLoad()
	player = GetMyHero()
	initVariables()
	drawMenu()
	mountBehaviorTree()
	print("Passive Follow Loaded")
	allies = GetPlayers(player.team, true, false)
	
	--[[if AutoUpdate then
		Update()
	end]]
end

