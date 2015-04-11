require 'LinkedList'

--[[
	GOAP SYSTEM 1.0 BETA
	DEVELOPED BY VIKTORGREGO 
]]

-------------------------------------------------------------------------------------
--Action Class
-------------------------------------------------------------------------------------
--[[
It serves as an example of how an Action should be structured to work with a Planning Algorithm

Properties
preconditions - Conditions to be achieved before the action can run. Each precondition must be presented in the following structure: {key:string, value: boolean} 
effects - effects caused by the action. Each effect must be presented in the following structure: {key:string, value: boolean} 
cost - Action Execution Cost
parent - the object who cast this action
target - the action who the action is cast into

Methods
addEffect - Inserts an effect in the effect list, must be cast in the constructor of child classes
addPrecondition - Inserts a precondition in the preconditions list, must be cast in the constructor of child classes
removeEffect - Remove an effect from the effect list
removePrecondition - Removes a precondition from preconditions list
isDone - Tells if the action is over
Run - Executes the Action
Print - Print for debug
reset - Resets all properties
contextCheck - Checks advanced things
simbolicCheck - Checks basic things, simulation method
]]
class 'Action'

function Action:__init(o)
	self.preconditions = {}
	self.effects = {}
	self.cost = 1
	self.parent = nil
	self.target = nil
	self.done = false
end

function Action:Run()
end

function Action:addPrecondition(o)
	self.preconditions[o.keyValue] = o
end

function Action:addEffect(o)
	self.effects[o.keyValue] = o
end

function Action:print()
	print("Action: Action");
end

function Action:isDone()
	return self.done
end

function Action:symbolicCheck(o)

	for v in pairs(o.descriptors) do
		if self.effects[v] ~= nil and self.effects[v].keyValue == v and self.effects[v].currValue == o.descriptors[v].goalValue and o.descriptors[v].goalValue ~= o.descriptors[v].currValue then
			return true
		end
	end
	return false
end


-------------------------------------------------------------------------------------
--WorldStateManager
-------------------------------------------------------------------------------------
--[[
This Class holds  a table of WorldStateDescription and manages this tables in search and other operations that requires world description

Properties
descriptors:WorldStateDescription Table - Holds the states that make the worldState
f: double - estimated total cost
g: double - walk cost
h: double - heuristic cost
parent: WorldStateManager - The parent node in a search Graph
parentAction: Action - The action that transitioned to this WorldStateDescription

Methods
addDescriptor - adds a WorldStateDescription to the descriptors table
isPerfect - Verify if all preconditions are satisfied, if true the plan is done
generateSucessor - Receives an Action and adds its modifications to the current World description, returns a new table of World Manager
Print - Print all descriptors inside the structure
]]

class 'WorldStateManager'

function WorldStateManager:__init(o)
	self.descriptors = {}
	self.f = 0.0
	self.g = 0.0
	self.h = 0.0
	self.len = 0
	self.parent = nil
	self.parentAction = nil
end

function WorldStateManager:__len()
	return self.len
end

function WorldStateManager:isPerfect()
	if Menu.common.devMode then print("Called WorldStateManager:isPerfect") end
	if(self.len == 0) then return false end
	
	for v in pairs(self.descriptors) do
		if(self.descriptors[v].currValue ~= self.descriptors[v].goalValue) then return false end
	end
	return true
end

function WorldStateManager:addDescriptor(o)
	self.descriptors[o.keyValue] = o
	self.len = self.len + 1
end

function WorldStateManager:generateSucessor(action)
	if Menu.common.devMode then print("Called generateSucessor") end

	local result = WorldStateManager()
	
	for v in pairs(self.descriptors) do
		local t_descriptor = WorldStateDescription({keyValue = self.descriptors[v].keyValue, currValue = self.descriptors[v].currValue, goalValue = self.descriptors[v].goalValue})
		result:addDescriptor(t_descriptor)
	end
	
	for v in pairs(action.effects) do
		if result[v] == nil then
			local t_descriptor = WorldStateDescription({keyValue = v, currValue = action.effects[v].currValue, goalValue = true})
			result:addDescriptor(t_descriptor) 
		else
			result[v].currValue = v.currValue
		end
	end
	
	for v in pairs(action.preconditions) do
		if result[v] == nil then 
			local t_descriptor = WorldStateDescription({keyValue = v, currValue = action:contextCheck(), goalValue = action.preconditions[v].goalValue})
			result:addDescriptor(t_descriptor) 
		else
			result[v].goalValue = v.goalValue
		end
	end

	result.parentAction = action
	return result
end

function WorldStateManager:__eq(o, p)
	if p == nil or o == nil and p ~= o then return false end 
	if(o.len ~= p.len) then return false end
	
	for v in pairs(o.descriptors) do
		if(p.descriptors[v] ~= o.descriptors[v]) then return false end
	end
	
	return true
end

function  WorldStateManager:print()
	count = 0
	for _ in pairs(self.descriptors) do count = count + 1 end
	print("descriptor size: "..count)
	
	for v in pairs(self.descriptors) do
		self.descriptors[v]:print()
	end
end

function  WorldStateManager:getType()
	return "WorldStateManager"
end

-------------------------------------------------------------------------------------
--WorldStateDescription
-------------------------------------------------------------------------------------
--[[
The WorldStateDescription class uses a single table to store a description of a key.

Properties
keyValue:string - stores the key to be described
currValue:boolean - the current value of the key
goalValue:boolean - the value that should be achieved

Methods
print - Show info about the key

When you want to initialize the parameter should be like: {keyValue = "canBuy", currValue = "true", goalValue = "true"}

]]

class 'WorldStateDescription'

function WorldStateDescription:__init(o)
	self.keyValue = o.keyValue or ""
	self.currValue = o.currValue or nil
	self.goalValue = o.goalValue or nil
end

function WorldStateDescription:print()
	print(self.keyValue, " ",  self.currValue, " ", self.goalValue)
end

function WorldStateDescription:__eq(o,p)
	if(o.keyValue == p.keyValue and o.currValue == p.currValue and o.goalValue == p.goalValue) then return true end
	return false
end

function  WorldStateDescription:getType()
	return "WorldStateDescription"
end


-------------------------------------------------------------------------------------
--Planner Class
-------------------------------------------------------------------------------------

--[[
Here we have the Planner class. This class creates a plan of action based in the GOALS given by the algorithm. Basically it looks over all 
actions and using a search algorithm, in our case A* and chooses the shortest path to a given world state description.

Properties
allActions:table - A table that contains all Actions that is possible to perform

Methods
initActions - Includes every possible actions in the Planner. Every time a new actions is programmed it should be included in the planner by inserting in the 
list by using initActions method.
getValidActions - Get all actions that are able to be executed 
]]

class 'Planner'

function Planner:__init(o)
	self.allActions = List()
	self:initActions()
end

function Planner:initActions()
	self.allActions:insertFirst(aBuyItem())
	--self.allActions:insertFirst(aGotoShop())
	--self.allActions:insertFirst(aTakeTurretCover())
	--self.allActions:insertFirst(aChooseLane())
	self.allActions:insertFirst(aGotoLane())
	--self.allActions:insertFirst(a)
end

function Planner:getValidActions(state)
	if Menu.common.devMode then print("called Planner:getValidActions") end
	result = List()
	for v in self.allActions:iterate() do 	

		if(v:symbolicCheck(state) and v:contextCheck()) then
			result:insertFirst(v) 
			--v:print()
		end
	end

	return result
end

function Planner:mountPlan(o)
	
	local result = List()
	i = o
	while (i ~= nil) do
		result:insertFirst(i)

		i = i.parent
	end
	return result
end

function Planner:BFSearch(start)
	local marked = List()
	local FIFO = List()
	
	FIFO:insertLast(start)
	
	
	while not FIFO:isEmpty() do
		local myState = FIFO:getFirst()
		
		if(myState:isPerfect()) then return self:mountPlan(myState) end
		
		local myActions = self:getValidActions(myState)

		local neighbors = List()
		for v in myActions:iterate() do
			local neighbor = FIFO:getFirst():generateSucessor(v)
			neighbors:insertFirst(neighbor)
		end
		
		for v in neighbors:iterate() do
			if not marked:contains(v) then
				marked:insertFirst(v)
				FIFO:insertLast(v)
				v.parent = FIFO:getFirst()
			end
		end
		FIFO:removeFirst()
	end
	return nil
end

--
-- 	END OF GOAP CODE
--


--
-- 	UTIL METHODS
--

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

function GetCloseTower(point, team)
	local towers = GetTowers(team)
	if #towers > 0 then
		local candidate = towers[1]
		for i=2, #towers, 1 do
			if (towers[i].health/towers[i].maxHealth > 0.1) and GetDistance(candidate, point) > GetDistance(point, towers[i]) then candidate = towers[i] end
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

--
--	END OF UTIL METHODS
--

--------------------------------------------------------------------------------------
--Inheritances of Action
--------------------------------------------------------------------------------------
--[[
keyList:
	kCanBuy
	kBoughtItem
	kUnderTurretCover
	kHaveLane
	kLaneChosen
	kInLane
]]

--------------------------------------------------------------------------------------
--Buy Item 
--------------------------------------------------------------------------------------

class 'aBuyItem' (Action)

function aBuyItem:__init(o)
	Action.__init(self)
	p1 = {keyValue = "kCanBuy", goalValue = true}
	self:addPrecondition(p1)
	e1 = {keyValue = "kBoughtItem", currValue = true}
	self:addEffect(e1)
end

function aBuyItem:contextCheck()
	return InFountain()
end

function aBuyItem:Run()
	if GetTickCount() > lastBuy + buyDelay then
			if GetInventorySlotItem(shopList[buyItemIndex].itemcode) ~= nil then
				self.done = true
				buyItemIndex = buyItemIndex + 1
			else
				lastBuy = GetTickCount()
				BuyItem(shopList[buyItemIndex].itemcode)
			end
		end
end

function aBuyItem:print()
	print("aBuyItem")
end

--------------------------------------------------------------------------------------
--Choose Lane
--------------------------------------------------------------------------------------

class 'aChooseLane' (Action)

function aChooseLane:__init(o)
	Action.__init(self)
	e1 = {keyValue = "kHaveLane", currValue = true}
	self:addEffect(e1)
end

function aChooseLane:contextCheck()
	return true
end

function aChooseLane:Run()
	currentLane = bottomPoint
	self.isDone = true
end

function aChooseLane:print()
	print("aChooseLane")
end

--------------------------------------------------------------------------------------
--Go to Lane
--------------------------------------------------------------------------------------

class 'aGotoLane' (Action)

function aGotoLane:__init(o)
	Action.__init(self)
	e1 = {keyValue = "kInLane", currValue = true}
	self:addEffect(e1)
end

function aGotoLane:contextCheck()
	if currentLane ~= nil then return GetDistance(currentLane, player) > 100
	else return false end 
end

function aGotoLane:Run()
	result = GetCloseTower(currentLane, player.team)
	player:MoveTo(result.x, result.y)
	if GetDistance(currentLane, player) < 100 then self.done = true end
end

function aGotoLane:print()
	print("aGotoLane")
end

--------------------------------------------------------------------------------------
--Go to Turret Cover
--------------------------------------------------------------------------------------

class 'aTakeTurretCover' (Action)

function aTakeTurretCover:__init(o)
	Action.__init(self)
	e1 = {keyValue = "kUnderTurretCover", currValue = true}
	self:addEffect(e1)
end

function aTakeTurretCover:contextCheck()
	return player.dead == false
end

function aTakeTurretCover:Run()
	local myTurret = GetCloseTower(player, player.team)
	followX = (allySpawn.x - myTurret.x)/(myTurret:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + myTurret.x
	followZ = (allySpawn.z - myTurret.z)/(myTurret:GetDistance(allySpawn)) * ((config.followChamp.followDist - 300) / 2 + 300) + myTurret.z
	player:MoveTo(math.floor(followX), math.floor(followZ))
	if(GetDistance(Vector(followX, followZ), player) < 30) then self.done = true end
end

function aTakeTurretCover:print()
	print("aTakeTurretCover")
end

--------------------------------------------------------------------------------------
--Go to Fountain
--------------------------------------------------------------------------------------

class 'aGotoShop' (Action)

function aGotoShop:__init(o)
	Action.__init(self)
	e1 = {keyValue = "kCanBuy", currValue = true}
	self:addEffect(e1)
end

function aGotoShop:contextCheck()
	return true
end

function aGotoShop:Run()
	player:MoveTo(BasePos.x, BasePos.y)
	if GetDistance(allySpawn, player) < 300 then self.done = true end
end

function aGotoShop:print()
	print("aGotoShop")
end

--
-- END OF Inheritances
--

shopList = {
	{itemcode = 3301, cost = 365},-- coin
	{itemcode = 3340, cost = 0}, --warding totem
	{itemcode = 1004, cost = 180},--Faerie Charm
	{itemcode = 3028, cost = 720},--Chalice of harmony
	{itemcode = 3096, cost = 500}, --Nomad Medallion
	{itemcode = 3114, cost = 600}, --Forbidden Idol
	{itemcode = 3069, cost = 2100}, --Talisman of Ascension
	{itemcode = 1001, cost = 365}, --Boots 
	{itemcode = 3108, cost = 820}, --Fiendish Codex
	{itemcode = 3174, cost = 2700}, --Athene's Unholy Grail
	{itemcode = 1028, cost = 400}, --Ruby Crystal
	{itemcode = 1033, cost = 500}, --Null magic mantle
	{itemcode = 3105, cost = 1900}, --Aegis of Legion
	{itemcode = 3158, cost = 1000},--Ionian Boots
	{itemcode = 1011, cost = 1000},--Giants Belt
	{itemcode = 3190, cost = 2800}, --Locket of Iron Solari
	{itemcode = 3143, cost = 2850}, --Randuins
	{itemcode = 3275, cost = 475}, --Homeguard
	{itemcode = 1058, cost = 1600}, --Large Rod
	{itemcode = 3089, cost = 1700} --Rabadon
}

--[[
keyList:
	kCanBuy
	kBoughtItem
	kUnderTurretCover
	kHaveLane
	kLaneChosen
	kInLane
]]

function ruleSystem()
	if(player.gold > shopList[buyItemIndex].cost) then
		WSD = WorldStateDescription({keyValue = "kBoughtItem", currValue = false, goalValue = true})
	elseif GetDistance(currentLane, player) > 100 then
		WSD = WorldStateDescription({keyValue = "kInLane", currValue = false, goalValue = true})
	end
	
	WSM:addDescriptor(WSD)
	
	plan = P:BFSearch(WSM)

	if plan ~= nil then
		currentAction = plan:getFirst()
		
		while currentAction.parentAction == nil do
			plan:removeFirst()
			currentAction = plan:getFirst()
		end
		
		currentAction.parentAction:Run()
	end

end

-----------------------------------------------------------------------------------
--Generic Methods
-----------------------------------------------------------------------------------
function OnTick()
	ruleSystem()
end

function drawMenu()
	Menu = scriptConfig("GOAP", "GOAP") 
	
	Menu:addSubMenu("Common Options", "common");
	
	Menu.common:addParam("devMode", "Developer Mode", SCRIPT_PARAM_ONOFF, false)
end

function startVariables()
	player = GetMyHero()

	buyItemIndex = 1
	buyDelay = 100
	lastBuy = 0
	bottomPoint = Vector(12100, 2100)
	currentLane = bottomPoint
	
	allySpawn = nil
	enemySpawn = nil
	detectSpawnPoints()

	P = Planner()
	WSM = WorldStateManager()
end

function OnLoad()
	drawMenu()
	startVariables()
end