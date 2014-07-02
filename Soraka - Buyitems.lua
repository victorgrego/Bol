--[[
	Auto buy items. 
	
	Build path, trinket purchase and speed optimisation added by One™.
]]

-- BUG: Upong buying the last item, tries to buy 'other' items and produces error as no other index in array

if GetMyHero().charName == "Soraka" then

	--[[ Config ]]
	PrintChat("Support Items Loaded: Soraka")
	shopList = {
	1028,--Ruby Crystal
	2049,--Sighstone
	3096,--Nomad Medallion
	3114,--Forbidden Idol
	3069,--Talisman of Ascension
	1001,--Boots 
	2045,--Ruby Sighstone
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
	--item ids can be found at many websites, ie: http://www.lolking.net/items/1004

	nextbuyIndex = 1
	wardBought = 0
	firstBought = false
	lastBuy = 0
	
	buyDelay = 100 --default 100

	--[[ Code ]]

	function OnTick()
		if firstBought == false and GetTickCount() - startingTime > 2000 then
			BuyItem(3301) -- coin
			BuyItem(3340) -- warding totem (trinket)
			firstBought = true
		end

		-- Run buy code only if in fountain
		if InFountain() then
			-- Continuous ward purchases
			--[[if GetTickCount() - wardBought > 30000 and GetTickCount() - startingTime > 8000 and GetInventorySlotItem(2044) == nil then
				BuyItem(2044) -- stealth ward (green)
				wardBought = GetTickCount()
			end]]
			
			-- Item purchases
			if GetTickCount() - startingTime > 5000 then	
				if GetTickCount() > lastBuy + buyDelay then
					if GetInventorySlotItem(shopList[nextbuyIndex]) ~= nil then
						--Last Buy successful
						nextbuyIndex = nextbuyIndex + 1
					else
						--Last Buy unsuccessful (buy again)
						BuyItem(shopList[nextbuyIndex])
						lastBuy = GetTickCount()
					end
				end
			end
		end
		
	end


	function OnLoad()
		if GetInventorySlotIsEmpty(ITEM_1) == false then
			firstBought = true
		end

		startingTime = GetTickCount()
	end
end