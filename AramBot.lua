--[[
	ARAMBOT 1.0
	DEVELOPED BY VIKTORGREGO 
	2015 APRIL
]]

require 'LinkedList'

function initVariables()
	min = gamestate.map.min
	max = gamestate.map.max
	ENEMY_CHAMP_WEIGHT = 10
	ALLY_CHAMP_WEIGHT = -10
	MINION_WEIGHT = 1
	MINION_INFLUENCE_RANGE = 500
	LOOSE = 50
	BONUS = 5
	TOWER_RANGE = 780
	TOWER_WEIGHT = 100
	TOWER_DISCOUNT = 100
	
	RESOLUTION = 200
	SQRT2RES = math.sqrt(2) * RESOLUTION + 3
	Grid = List()
	
	EnemyMinions = minionManager(MINION_ENEMY, 10000, myHero, MINION_SORT_HEALTH_ASC)
	AllyMinions = minionManager(MINION_ALLY, 10000, myHero, MINION_SORT_HEALTH_DEC)
	
	myTrueRange = myHero.range + myHero.boundingRadius-3
	
	print("Walker Loaded!!!")
	player = GetMyHero()
end
--Values DO NOT CHANGE
SCRIPT_START_TIME = 0
WALK_ERROR = 300
-------Orbwalk info-------
local lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
local myTrueRange = 0
local myTarget = nil
-------/Orbwalk info------
ts = TargetSelector(TARGET_LOW_HP, myTrueRange)

-- CELL ANALYSIS AREA
class 'Cell'
function Cell:__init(center, neighbors)
	self.center = center or Vector(0,0,0)
	self.neighbors = neighbors or List()
	self.weight = 0
end

function Cell:__eq(o,p)
	if o == nil or p == nil then return false
	elseif center ~= center or weight ~= weight then return false end
	return true
end

function Cell:inside(pos)
	--print("tryInside")
	local halfRes = RESOLUTION/2
	--print("Champ pos "..pos.x.." Cell MIN MAX "..(self.center.x -  halfRes).." "..(self.center.x + halfRes))
	--if VectorType(self.center) then print("true") end 
	--print("Champ pos "..pos.z.." Cell pos "..(self.center.z +  halfRes))
	if pos.x > self.center.x - halfRes and pos.x < self.center.x + halfRes then
		if pos.z > self.center.z - halfRes and pos.z < self.center.z + halfRes then
			return true
		end
	end
	return false
end

function Cell:getPosition()
	return self.center.x, self.center.y, self.center.z
end

-- END OF CELL ANALYSIS AREA

function OnDraw()
	DrawCircle3D(myHero.x, myHero.y, myHero.z, myTrueRange, 1, 0xffffffff, 8 )

	for v in Grid:iterate() do
		if v ~= nil then
			if Menu.common.drawCenters then DrawCircle3D(v.center.x, 0, v.center.z, RESOLUTION/2, 1, 0xffffff00, 8 ) end
			--DrawRectangleOutline(v.center.x, v.center.y, RESOLUTION, RESOLUTION, 0xffffffff, 10)
			if Menu.common.drawNeighbors then
				for u in v.neighbors:iterate() do
					DrawLine3D(v.center.x, 0, v.center.z, u.center.x, 0, u.center.z, 1, 0xffff00ff)
				end
			end
			if Menu.common.drawText then
				DrawText3D(tostring(v.weight), v.center.x, 0, v.center.z, 12, 0xffffff00, true)
			end
		end
	end
end

-- STARTS THE GRID AT GAME START
function GenerateGrid()
	
	
	print(min.x)
	print(min.y)
	print(max.x)
	print(max.y)
	
	--Creating a grid, except for cells that is inside walls
	for i = min.x, max.x, RESOLUTION do
		for j = min.y, max.y, RESOLUTION do
			if not IsWall(D3DXVECTOR3(i,0,j)) then
				Grid:insertFirst(Cell(Vector(i,0,j)))
			end
		end
	end
	
	--Making the neighbors table of each cell
	for i in Grid:iterate() do
		for j in Grid:iterate() do
			if GetDistance(i.center,j.center) < SQRT2RES and i ~= j then
				i.neighbors:insertFirst(j)
			end
		end
	end
end

function drawMenu()
	
end
--
-- UTIL FUNCTIONS
--
function GetPlayers(team, includeDead, includeSelf, range) -- Returns all players from a team, options dead and self
	local players = {}
	local result = {}
	local r = range or nil
	
	if team == player.team then
		players = GetAllyHeroes()
	else
		players = GetEnemyHeroes()
	end
	
	for i=1, #players, 1 do
		if players[i].visible and (not players[i].dead or players[i].dead == includeDead) then
			if r ~= nil and player:GetDistance(players[i]) <= r then
				table.insert(result, players[i])
			elseif r == nil then
				table.insert(result, players[i])
			end
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

-- return a List of towers
function GetTowers(team)
	local towers = List()
	for i=1, objManager.maxObjects, 1 do
		local tower = objManager:getObject(i)
		if tower ~= nil and tower.valid and tower.type == "obj_AI_Turret" and tower.visible and tower.team == team then
			towers:insertFirst(tower)
		end
	end
	if #towers > 0 then
		return towers
	else
		return false
	end
end

--
--	END OF UTIL FUNCTIONS
--

-- IM UPDATE AREA

--UPDATES GRID IN TERMS OF CHAMPIONS
function updateMinions(j)
	
	for _, v in ipairs(EnemyMinions.objects) do
		--[[if ValidTarget(minion) and GetDistance(v) <= myHero.range then
		
			local myDmg = getDmg("AD", v, myHero)
			if v.health <= myDmg then myHero:Attack(v) end
		end]]
		local dist = GetDistance(j.center, v)
		if dist > myHero.range + LOOSE then goto continue end 
		
		local maxDist = 2* myHero.range
		
		if dist < myHero.range - LOOSE then j.weight = math.max(dist, j.weight)
		--elseif dist > myHero.range + LOOSE and dist < maxDist then j.weight = j.weight + (maxDist - dist)
		else j.weight = math.max (myHero.range + BONUS, j.weight) end
		j.weight = math.floor(j.weight)
		
		::continue::
	end
	
	for _, v in ipairs(AllyMinions.objects) do
		--[[if ValidTarget(minion) and GetDistance(v) <= myHero.range then
		
			local myDmg = getDmg("AD", v, myHero)
			if v.health <= myDmg then myHero:Attack(v) end
		end]]
		local dist = GetDistance(j.center, v)
		if dist > myHero.range + LOOSE then goto continue end 
		
		local maxDist = 2* myHero.range
		if dist < myHero.range - LOOSE then j.weight = math.max(MINION_RANGE - GetDistance(j.center, v), j.weight)
		--elseif dist > myHero.range + LOOSE and dist < maxDist then j.weight = j.weight + (maxDist - dist)
		else j.weight = math.max (myHero.range + BONUS, j.weight) end
		j.weight = math.floor(j.weight)
		
		::continue::
	end
end

function updateChampions()
	--print("Champions")
	local allies = GetPlayers(player.team, false, false)
	local enemies = GetPlayers(TEAM_ENEMY, false, false)
	
	for i, u in ipairs(allies) do
		for j in Grid:iterate() do
			if GetDistance(j, Vector(u)) < RESOLUTION * 2 and j:inside(Vector(u)) then j.weight = j.weight + ALLY_CHAMP_WEIGHT end
		end
	end
	
	for i, u in ipairs(enemies) do
		--print("X: "..u.x.." Y: "..u.y.." Z: "..u.z)
	
		for j in Grid:iterate() do
			if GetDistance(j.center,Vector(u)) < RESOLUTION * 2 and j:inside(Vector(u)) then j.weight = j.weight + ENEMY_CHAMP_WEIGHT end
		end
	end
end

function updateTowers(i, allies, enemies)
		for j in enemies:iterate() do
			if GetDistance(i.center, j) < TOWER_RANGE then i.weight = math.min(math.floor(TOWER_RANGE - GetDistance(i.center, j)) * -1, i.weight) end
		end
		
		for j in allies:iterate() do
			if GetDistance(i.center, j) < TOWER_RANGE then i.weight = math.max(math.floor(TOWER_RANGE - GetDistance(i.center, j)) - TOWER_DISCOUNT, i.weight) end
		end
end

-- CALL ALL FUNCTIONS TO UPDATE
function updateInfluenceMap()
	-- putting 0 on values
	local allies = GetTowers(player.team)
	local enemies = GetTowers(TEAM_ENEMY)
	EnemyMinions:update()
	
	for u in Grid:iterate() do
		u.weight = 0
	end
	
	for u in Grid:iterate() do
		updateTowers(u,allies,enemies)
		updateMinions(u)
	end
end

function chooseBestPosition()
	local bestPoint = nil
	local possibilities = List()
	if(Grid:isEmpty()) then return end
	possibilities:insertFirst(Grid:getFirst())
	
	for v in Grid:iterate() do
		if not possibilities:isEmpty() and v.weight > possibilities:getFirst().weight then 
			possibilities = List()
			possibilities:insertFirst(v)
		elseif v.weight == possibilities:getFirst().weight then
			possibilities:insertFirst(v)
		end
	end
	
	local currentDist = 9999999
	for v in possibilities:iterate() do
		if(bestPoint == nil) then bestPoint = v 
		elseif GetDistance(v.center, Vector(0,0)) < currentDist then
			bestPoint = v
			currentDist = GetDistance(v.center, Vector(0,0))
		end
	end
	
	if bestPoint ~= nil and heroCanMove() then player:MoveTo(bestPoint.center.x, bestPoint.center.z) end
end

-- END OF IM UPDATE AREA

--
-- ORBWALKER
--


function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end 
 
function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end 

function _OrbWalk()
	if ts.target ~= nil then print(ts.target) 
	myTarget = ts.target end
	if myTarget ~=nil and GetDistance(myTarget) <= myTrueRange then		
		if timeToShoot() then
			player:Attack(myTarget)
		elseif heroCanMove() then
			chooseBestPosition()
		end
	else		
		chooseBestPosition()
	end
end

function OnProcessSpell(object, spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end 
	end
end

function OnTick()
	--walker:update()
	
end

function OnLoad()
	
end

--
-- END OF ORBWALKER
--

function OnTick()
	ts.range = myHero.range + myHero.boundingRadius - 3
	ts:update()
	_OrbWalk()
	updateInfluenceMap()
	--chooseBestPosition()
end

function OnLoad()
	
	gamestate = GetGame()
	initVariables()
	drawMenu()
	Menu = scriptConfig("Passive Follow", "Passive Follow") 
	
	Menu:addSubMenu("Commons", "common")
	
	Menu.common:addParam("drawNeighbors", "Draw Neighbors", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("drawCenters", "Draw Cell Centers", SCRIPT_PARAM_ONOFF, true)
	Menu.common:addParam("drawText", "Draw Weights", SCRIPT_PARAM_ONOFF, true)
	GenerateGrid()
	
end