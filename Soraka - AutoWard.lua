--[[
Ikita's Auto Ward 1.0 for BoL Studio
Sight Wards

Trinket use added by One™.
Now uses SightStone by Victorgrego

-Now does Perfect Warding

]]

PrintChat("AutoWard enabled")

--[[ Config ]]
local HK = nil --F6 117 default
local wardRange = 600 --Ward range is 600.

--Nothing
local scriptActive = true
local wardTimer = 0
local wardSlot = nil
local wardMatrix = {}
local wardDetectedFlag = {}
local lastWard = 0
wardMatrix[1] = {10180.18, 8875.13, 3920.88, 5017.27, 4728, 7151.64, 10148,  3883, 6867.68, 9720.86, 9233.13, 4354.54}
wardMatrix[2] = { 4969.32, 5390.57, 9477.78, 8954.09, 8336, 4719.66,  2839, 11577, 9567.63, 7501.50, 6094.48, 7079.51}
wardMatrix[3] = {}
for i = 1, 12 do
	--Ward present nearby ?
	wardMatrix[3][i] = false
	wardDetectedFlag[i] = false
end

--[[ Code ]]

function wardUpdate()
	for i = 1, 12 do
		wardDetectedFlag[i] = false
	end
	for k = 1, objManager.maxObjects do
		local object = objManager:GetObject(k)
		if object ~= nil and (string.find(object.name, "Ward") ~= nil or string.find(object.name, "Wriggle") ~= nil) then
			for i = 1, 12 do
				if math.sqrt((wardMatrix[1][i] - object.x)*(wardMatrix[1][i] - object.x) + (wardMatrix[2][i] - object.z)*(wardMatrix[2][i] - object.z)) < 1100 then
					wardDetectedFlag[i] = true
					wardMatrix[3][i] = true
				end
			end
		end
		for i = 1, 12 do
			if wardDetectedFlag[i] == false then
				wardMatrix[3][i] = false
			end
		end
	end
	wardTimer = GetTickCount()
end

function OnTick()
	if scriptActive then
		if GetTickCount() - wardTimer > 10000 then
			wardUpdate()
		end	

		if GetInventorySlotItem(2049) ~= nil then
			wardSlot = GetInventorySlotItem(2049)
		elseif GetInventorySlotItem(2045) ~= nil then
			wardSlot = GetInventorySlotItem(2045)
		elseif (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340) then
			wardSlot = GetInventorySlotItem(3340)
		elseif (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350) then
			wardSlot = GetInventorySlotItem(3350)
		elseif GetInventorySlotItem(2044) ~= nil then
			wardSlot = GetInventorySlotItem(2044)
		elseif GetInventorySlotItem(2043) ~= nil then
			wardSlot = GetInventorySlotItem(2043)
		else
			wardSlot = nil
		end

		for i = 1, 12 do
			if wardSlot ~= nil and GetTickCount() - lastWard > 2000 then
				if math.sqrt((wardMatrix[1][i] - player.x)*(wardMatrix[1][i] - player.x) + (wardMatrix[2][i] - player.z)*(wardMatrix[2][i] - player.z)) < 600 and wardMatrix[3][i] == false then
					CastSpell( wardSlot, wardMatrix[1][i], wardMatrix[2][i] )
					lastWard = GetTickCount()
					wardMatrix[3][i] = true
					break
				end
			end
		end
	end	
end



function OnWndMsg(msg,key)
    if key == HK then
		if msg == KEY_DOWN then
			if scriptActive then
				scriptActive = false
				PrintChat("AutoWard disabled")
			else
				scriptActive = true
				PrintChat("AutoWard enabled")
			end
        end
    end
end
    