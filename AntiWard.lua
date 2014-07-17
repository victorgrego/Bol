--[[
ANTIWARD VERSION 1.0 BY VICTORGREGO
]]

green = ARGB(255,0,255,000)
yellow = ARGB(255,255,255,000)
purple = ARGB(255,230,93,255)

wards = {}
visionWards = {}

function OnDeleteObj(object)
	if object.name:lower():find("ward") or object.name:lower():find("totem") then
		for i = 1, #wards, 1 do
			if (object.name:lower():find("ward") or object.name:lower():find("totem")) and object.x == wards[i].pos.x and object.y == wards[i].pos.y then
				table.remove(wards, i)
				break
			end
		end
		
		for i = 1, #visionWards, 1 do
			if object.name:lower():find("ward") and object.x == visionWards[i].pos.x and object.y == visionWards[i].pos.y then
				table.remove(visionWards, i)
				break
			end
		end
	end
end

function OnProcessSpell(unit,spell)
	if unit.name == player.name then print(spell.name) end
	if unit.team == TEAM_ENEMY then
		if spell.name:lower() == "sightward" or spell.name:lower() == "itemghostward" then
			table.insert(wards,{name = spell.name, color = green, pos = Vector(spell.endPos), duration = os.clock() + 180})
		elseif spell.name:lower() == "trinkettotemlvl1" then
			table.insert(wards,{name = spell.name, color = yellow, pos = Vector(spell.endPos), duration = os.clock() + 60})
		elseif spell.name:lower() == "visionward" then
			table.insert(visionWards,{name = spell.name, color = purple, pos = Vector(spell.endPos)})
		end
	end
end


function OnDraw()
	
	for i = 1, #wards, 1 do
		local wPos = WorldToScreen(D3DXVECTOR3(wards[i].pos.x, wards[i].pos.y, wards[i].pos.z))
		if wards[i].duration - os.clock() < 0 then 
			table.remove(wards, i) 
			break
		end
		
		local pMinimap = GetMinimap(wards[i].pos)
		
		DrawCircle(wards[i].pos.x, wards[i].pos.y, wards[i].pos.z, 90, wards[i].color)
		DrawText(TimerText(wards[i].duration - os.clock()), 20, wPos.x - 15, wPos.y-11, wards[i].color)
		DrawText("X", 12, pMinimap.x-1, pMinimap.y-6, wards[i].color)
	end
	
	for i = 1, #visionWards, 1 do
		DrawCircle(visionWards[i].pos.x, visionWards[i].pos.y, visionWards[i].pos.z, 70, visionWards[i].color)
		local pMinimap = GetMinimap(visionWards[i].pos)
		DrawText("X", 12, pMinimap.x-1, pMinimap.y-6, visionWards[i].color)
	end
end