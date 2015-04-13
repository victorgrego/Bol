--[[
	ARAMBOT 1.0
	DEVELOPED BY VIKTORGREGO 
	2015 APRIL
]]

require 'LinkedList'
require 'AutoLevel'
require 'AutoBuy'
require 'AutoCombo'

function initVariables()
	min = gamestate.map.min
	max = gamestate.map.max
	ENEMY_CHAMP_WEIGHT = 10
	ALLY_CHAMP_WEIGHT = -10
	MINION_WEIGHT = 1
	MINION_RANGE = 500
	MINION_INFLUENCE_RANGE = 500
	LOOSE = 50
	TOWER_LOOSE = 20
	BONUS = 5
	TOWER_RANGE = 950
	TOWER_WEIGHT = 200
	TOWER_DISCOUNT = 100
	
	RECALCULATION_DELAY = 200
	LAST_RECALCULATION = 0
	
	myFountain = myGetFountain()
	
	RESOLUTION = 150
	SQRT2RES = math.sqrt(2) * RESOLUTION + 3
	Grid = List()
	
	EnemyMinions = minionManager(MINION_ENEMY, 20000, myHero, MINION_SORT_HEALTH_ASC)
	EnemyMinionsFarm = minionManager(MINION_ENEMY, myHero.range, myHero, MINION_SORT_HEALTH_ASC)
	AllyMinions = minionManager(MINION_ALLY, 20000, myHero, MINION_SORT_HEALTH_DEC)
	
	myTrueRange = myHero.range + myHero.boundingRadius-3
	
	yikesTurret = nil
	
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
local myMinion = nil
local myTower = nil
-------/Orbwalk info------
ts = TargetSelector(TARGET_LOW_HP_PRIORITY, myTrueRange + 50)

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
	local halfRes = RESOLUTION/2
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

function GetCloseTower(hero, team)
	local towers = GetTowers(team)
	if #towers > 0 then
		local candidate = towers:getFirst()
		for i in towers:iterate() do
			if (i.health/i.maxHealth > 0.1) and  GetDistance(candidate, hero) > GetDistance(i, hero) then candidate = i end
		end
		return candidate
	else
		return false
	end
end

function getPercentHealth(unit)
	return unit.health/unit.maxHealth*100
end

function GetNextEnemyTower()
	local NextEnemyTower, dist 
	for i=1, objManager.maxObjects, 1 do
		local tower = objManager:getObject(i)
		if tower ~= nil and (tower.type == "obj_AI_Turret" or tower.type == "obj_HQ"--[[ or tower.name == "Order_Inhibit_Gem.troy" or tower.name == "Chaos_Inhibit_Gem.troy"]]) and ValidTarget(tower) then	
			if not NextEnemyTower then
				NextEnemyTower = tower
				dist = GetDistance(tower)
			else
				local tD = GetDistance(tower)
				if tD < dist then
					NextEnemyTower, dist = tower, tD			
				end
			end			
		end
	end
	if NextEnemyTower then
		AllyMinionsAround = minionManager(MINION_ALLY, 1000, NextEnemyTower, MINION_SORT_HEALTH_ASC)
		if AllyMinionsAround.iCount >= 1 then
			return NextEnemyTower
		end		
	end		
end

function myGetFountain()
	if player.team == TEAM_BLUE then return GetFountain() 
	else return Vector(12184, 0, 11844)
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
		
		local tfDist = GetDistance(v, myFountain)
		local pfDist = GetDistance(j.center, myFountain)
		local w = tfDist / pfDist
		
		if dist < myHero.range - LOOSE then j.weight = math.max(w*(dist + (100 - getPercentHealth(v))), j.weight)
		--elseif dist > myHero.range + LOOSE and dist < maxDist then j.weight = j.weight + (maxDist - dist)
		else j.weight = math.max (w*(myHero.range + BONUS + (100 - getPercentHealth(v))), j.weight) end
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
		
		
		if dist <= myHero.range then 
			j.weight = math.max(GetDistance(j.center, v), j.weight) 
			j.weight = math.floor(j.weight)
		end
		--elseif dist > myHero.range + LOOSE and dist < maxDist then j.weight = j.weight + (maxDist - dist)
		
		
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
			
			local dist = GetDistance(i.center, j)
			
			local tfDist = GetDistance(j, myFountain)
			local pfDist = GetDistance(i.center, myFountain)
			local w = tfDist / pfDist
			if dist > TOWER_RANGE then goto continue end
			
			local allMinCount = 0
			for _, v in ipairs(AllyMinions.objects) do
				if GetDistance(j,v) < 850 then 
					allMinCount = allMinCount + 1
				end
			end
			
			if(allMinCount >= 2) then 
				if dist < myHero.range then
					i.weight =  math.floor(w * dist) 
				else--if dist < myHero.range + LOOSE then 
					i.weight = math.floor(2*w*(TOWER_RANGE - dist))
				--else
				--	i.weight = math.floor(w*(myHero.range + 50))
				end
			else
				 if dist > 400 then 
				 --[[i.weight = math.min(math.floor(TOWER_RANGE - GetDistance(i.center, j)) * -1, i.weight)]] 
					i.weight = -TOWER_RANGE
				else
					i.weight = -999999
				 end 
			end
			::continue::
		end
		
		for j in allies:iterate() do
			local dist = GetDistance(i.center, j)
			if dist < TOWER_RANGE and dist > 400 then i.weight = math.max(math.floor(TOWER_RANGE - GetDistance(i.center, j)) - TOWER_DISCOUNT, i.weight) end
		end
end

-- CALL ALL FUNCTIONS TO UPDATE
function updateInfluenceMap()
	-- putting 0 on values
	local allies = GetTowers(player.team)
	local enemies = GetTowers(TEAM_ENEMY)
	EnemyMinions:update()
	AllyMinions:update()
	
	myTrueRange = myHero.range + myHero.boundingRadius - 3
	ts.range = myTrueRange
	EnemyMinionsFarm.range = myTrueRange
	ts:update()
	EnemyMinionsFarm:update()
	
	if GetTickCount() > LAST_RECALCULATION + RECALCULATION_DELAY then 
		
		for u in Grid:iterate() do
			u.weight = 0
		end
		
		for u in Grid:iterate() do
			updateMinions(u)
			updateTowers(u,allies,enemies)
		end
		LAST_RECALCULATION = GetTickCount()
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
		elseif GetDistance(v.center, myFountain) < currentDist then
			bestPoint = v
			currentDist = GetDistance(v.center, Vector(0,0))
		end
	end
	
	if bestPoint ~= nil then player:MoveTo(bestPoint.center.x, bestPoint.center.z) end
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
	local RealTarget = ValidTarget(myTarget) and myTarget or myTower or myMinion
	if RealTarget ~= nil and GetDistance(RealTarget) <= myTrueRange then
		if timeToShoot() then
			player:Attack(RealTarget)
			return
		elseif heroCanMove() then
			chooseBestPosition()
			return
		end
	elseif heroCanMove() then		
		chooseBestPosition()
		return
	end
end

--
-- END OF ORBWALKER
--

--
-- COMMON FUNCTIONS
--

function OnProcessSpell(object, spell)
	if object.type == "obj_AI_Turret" and spell.name:lower():find("attack") and spell.target == player then 
		yikesTurret = GetCloseTower(myHero, TEAM_ENEMY)
	elseif object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = (GetTickCount() - GetLatency()/2) + 25
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end 
	end
end

function OnDraw()
	DrawCircle3D(myHero.x, myHero.y, myHero.z, myTrueRange, 1, 0xffffffff, 8 )
	DrawCircle3D(myGetFountain().x, myGetFountain().y, myGetFountain().z, myTrueRange, 1, 0xffffffff, 8 )
	for v in Grid:iterate() do
		if v ~= nil then
			if Menu.common.drawCenters then DrawCircle3D(v.center.x, 0, v.center.z, RESOLUTION/2, 1, 0xffffff00, 8 ) end
			if Menu.common.drawNeighbors then
				for u in v.neighbors:iterate() do
					--DrawLine3D(v.center.x, 0, v.center.z, u.center.x, 0, u.center.z, 1, 0xffff00ff)
					--OnScreen(u, v)
				end
			end
			if Menu.common.drawText then
				DrawText3D(tostring(v.weight), v.center.x, 0, v.center.z, 12, 0xffffff00, true)
			end
		end
	end
end

function OnTick()
	if yikesTurret ~= nil then
		local followX = (2 * myHero.x) - yikesTurret.x
		local followZ = (2 * myHero.z) - yikesTurret.z
		player:MoveTo(followX, followZ)
		if GetDistance(yikesTurret, myHero) > 1000 then yikesTurret = nil end
		return
	end
	updateInfluenceMap()
	myTarget, myMinion, myTower = ts.target, EnemyMinionsFarm.objects[1], GetNextEnemyTower()
	_OrbWalk()	
end

function OnLoad()
	gamestate = GetGame()
	initVariables()
	drawMenu()
	Menu = scriptConfig("AramBot", "AramBot") 
	
	Menu:addSubMenu("Commons", "common")
	
	Menu.common:addParam("drawNeighbors", "Draw Neighbors", SCRIPT_PARAM_ONOFF, false)
	Menu.common:addParam("drawCenters", "Draw Cell Centers", SCRIPT_PARAM_ONOFF, false)
	Menu.common:addParam("drawText", "Draw Weights", SCRIPT_PARAM_ONOFF, false)
	GenerateGrid()
	
end