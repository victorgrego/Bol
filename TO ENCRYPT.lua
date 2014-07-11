
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
	
	actions["startTime"] = function()
		if GetGameTimer() > SCRIPT_START_TIME then return true
		else return false end
	end
	
	actions["noPartner"] = function()
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
	return result
end

_G.mountBehaviorTree = function()
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
