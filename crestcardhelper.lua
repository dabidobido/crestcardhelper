_addon.name = 'crestcardhelper'
_addon.author = 'Dabidobido'
_addon.version = '1.0.0'
_addon.commands = {'cch'}

require('logger')
require('tables')

local delay = 20
local number_of_items = T{}
local number_of_crystals = T{}
local crest_cards = {
	[9764] = "liquefaction sphere 5",
	[9765] = "induration sphere 4",
	[9766] = "detonation sphere 5",
	[9767] = "scission sphere 5",
	[9768] = "impaction sphere 5",
	[9769] = "reverberation sphere 4",
	[9770] = "transfixion sphere 5",
	[9771] = "compression sphere 5",
}

local crystal_used = {
	[9764] = 4100,
	[9765] = 4100,
	[9766] = 4098,
	[9767] = 4098,
	[9768] = 4098,
	[9769] = 4100,
	[9770] = 4098,
	[9771] = 4098,
}

local cluster_map = {
	[4108] = 4100,
	[4106] = 4098,
}

local sphere_ids = { 
	[9524] = "Lique. Sphere", 
	[9525] = "Indur. Sphere", 
	[9526] = "Deton. Sphere", 
	[9527] = "Sciss. Sphere", 
	[9528] = "Impac. Sphere", 
	[9529] = "Rever. Sphere",
	[9530] = "Trans. Sphere", 
	[9531] = "Compr. Sphere",
	[9532] = "Fusion Sphere", 
	[9533] = "Disto. Sphere", 
	[9534] = "Fragm. Sphere", 
	[9535] = "Gravi. Sphere",
	[9536] = "Light Sphere", 
	[9537] = "Darkn. Sphere"
}

windower.register_event('addon command', function (...)
	local args = T{...}
	local command = args[1]

	if command == 'start' then
		
		windower.send_command('lua r craft')
		coroutine.sleep(0.2)
		windower.send_command('craft delay ' .. delay)
		windower.send_command('craft food "Kitron Macaron"')
		
		check_inventory()
		if check_enough_crystals() then
			while number_of_items:length() > 0 do
				local total_number = 0
				for id, number in pairs(number_of_items) do
					windower.send_command('craft make "' .. crest_cards[id] .. '" ' .. number)
					total_number = total_number + number
				end
				coroutine.sleep(total_number * delay + delay)
				check_inventory()
				if not check_enough_crystals() then break end
			end
		end
		windower.send_command('input /p <call16>')
	elseif command == 'trade' then
		
		local player = windower.ffxi.get_player()
		if player then
			if player.target_index ~= nil then
				local target = windower.ffxi.get_mob_by_index(player.target_index)
				if target and target.name == "Synthesis Focuser II" and target.distance < 36 then
					windower.send_command('lua r tradenpc')
					coroutine.sleep(0.2)
					local spheres = get_spheres_in_inventory()
					while get_count(spheres) > 0 do
						spheres = trade_spheres_in_inventory(spheres)
					end
					print("Trade spheres done")
				else
					print("Please target the Synthesis Focuser")
				end
			else
				print("Please target the Synthesis Focuser")
			end
		end
	else
		help_command()
	end
end)

function get_count(spheres)
	local count = 0
	for _,_ in pairs(spheres) do
		count = count + 1
	end
	return count
end

function get_spheres_in_inventory()
	local spheres = {}
	local inventory = windower.ffxi.get_items(0)
	for i = 1, inventory.max, 1 do
		if inventory[i] then
			local item_id = inventory[i].id
			if sphere_ids[item_id] then
				if spheres[item_id] == nil then
					spheres[item_id] = inventory[i].count
				else
					spheres[item_id] = spheres[item_id] + inventory[i].count
				end
			end
		end
	end
	return spheres
end

function trade_spheres_in_inventory(spheres)
	local slots = 0
	local trade_string = "tradenpc "
	local return_spheres = {}
	for id, number in pairs(spheres) do
		if slots < 8 then
			local slots_used = math.ceil(number / 12)
			local slots_avail = 8 - slots
			if slots_avail < slots_used then slots_used = slots_avail end
			slots = slots + slots_used
			local number_of_spheres_to_trade = math.min(slots_used * 12, number)
			trade_string = trade_string .. math.min(slots_used * 12, number) .. ' "' .. sphere_ids[id] .. '" '
			if number > number_of_spheres_to_trade then
				return_spheres[id] = number - number_of_spheres_to_trade
			end
		else
			return_spheres[id] = number
		end
	end
	windower.send_command(trade_string)
	coroutine.sleep(3)
	return return_spheres
end

function check_inventory()
	local inventory = windower.ffxi.get_items(0)
	number_of_items = T{}
	number_of_crystals = T{}
	
	for i = 1, inventory.max, 1 do
		if inventory[i] then
			local item_id = inventory[i].id
			if crest_cards[item_id] then
				if number_of_items[item_id] == nil then
					number_of_items[item_id] = inventory[i].count
				else
					number_of_items[item_id] = number_of_items[item_id] + inventory[i].count
				end
			elseif crystal_used[item_id] then
				if number_of_crystals[item_id] == nil then
					number_of_crystals[item_id] = inventory[i].count
				else
					number_of_crystals[item_id] = number_of_crystals[item_id] + inventory[i].count
				end
			elseif cluster_map[item_id] then
				if number_of_crystals[cluster_map[item_id]] == nil then
					number_of_crystals[cluster_map[item_id]] = inventory[i].count * 12
				else
					number_of_crystals[cluster_map[item_id]] = number_of_crystals[cluster_map[item_id]] + inventory[i].count * 12
				end
			end
		end
	end
end

function check_enough_crystals()
	local total_crystals_needed = {}
	for id, number in pairs(number_of_items) do
		if total_crystals_needed[crystal_used[id]] == nil then
			total_crystals_needed[crystal_used[id]] = number
		else
			total_crystals_needed[crystal_used[id]] = total_crystals_needed[crystal_used[id]] + number
		end
	end
	local got_enough_crystals = true
	for id, number in pairs(total_crystals_needed) do
		if number > number_of_crystals[id] then
			got_enough_crystals = false
			if id == 4100 then print('Need ' .. tostring(number - number_of_crystals[id]) .. " more Lightning Crystals")
			elseif id == 4098 then print('Need ' .. tostring(number - number_of_crystals[id]) .. " more Wind Crystals")
			end
			break
		end
	end
	return got_enough_crystals
end

function help_command()
	print('Sets craft delay to 20 and automatically sends craft commands to desynth all cards in inventory')
	print('Valid commands:')
	print('  start  : sends craft commands based on all crest cards in inventory')
	print('  trade  : trades all spheres in inventory to Synthesis Focuser II')
end