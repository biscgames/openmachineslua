return function(machines_grid,api)

function update_extractor(self,grid,r,c,extract_below)
	local ahead = grid[r][c+1]
	local above = grid[r-1]and grid[r-1][c] or nil
	local below = grid[r+1]and grid[r+1][c] or nil
	self.has_storage = ahead and ahead ~= 'e"' and ahead.type == "storage"
	local has_dep_above = above and above ~= 'e"' and above.type == "deposit"
	local has_dep_below = below and below ~= 'e"' and below.type == "deposit"
	if not self.has_storage then return end
	if has_dep_above then
		local dep_items = above.items_table
		local limit = math.min(#dep_items,self.extract)
		ahead.storage:add_item(dep_items[math.random(1,limit)])
	end
	if has_dep_below and extract_below then
		local dep_items = below.items_table
		local limit = math.min(#dep_items,self.extract)
		ahead.storage:add_item(dep_items[math.random(1,limit)])
	end
end
api.register_machine("default:extractor",{
	name = "Extractor",
	img_m = "extractor.png",
	type = "machine",

	extract = 3,
	pwr_on = false,
	has_storage = false,

	on_update = function(self,grid,r,c)
		update_extractor(self,grid,r,c,false)
	end
})
api.add_machine_to_shop("default:extractor")
api.register_machine("default:advancedextractor",{
	name = "Advanced Extractor",
	img_m = "advanced_extractor.png",
	type = "machine",

	extract = 3,
	extract_below = true,
	pwr_on = false,
	has_storage = false,

	on_update = function(self,grid,r,c)
		update_extractor(self,grid,r,c,true)
	end
})
api.add_machine_to_shop("default:advancedextractor")

end