api = {}
local registered_deposits = {}
local registered_machines = {}
local registered_sections = {}
api.sections = {}
api.shop_machines = {}

api.inv_system = {
	items = {},
	stack_limit = 128,
	can_fit = 9
}
--[[

	the inventory:find(proc) method is used to find an item
	by running the function recieved as an argument.
	if returned a truthy value, return both index and item in order
	or else return 2 nil values.

--]]
function api.inv_system:find(proc)
	for i,item in ipairs(self.items) do
		if proc(item,i) then return i,item end
	end
	return nil,nil
end
--[[
	the inventory:add_item(item_definition) method is used to add items to the inventory.items table.
	this method handles any stacks going above the stack limit, unlike manually adding it yourself
	unless your method fully calculates with stack_limit
]]
function api.inv_system:add_item(item_definition)
	local i,existing = self:find(function(item)
		return item.name==item_definition.name and item.stack<self.stack_limit 
	end)
	local function _add_item(stack)
		stack = stack or item_definition.stack
		local clone_attributes = api.dpcopy(item_definition.attributes)
		self.items[#self.items+1]= {
			name = item_definition.name,
			stack = stack,
			image = item_definition.image,
			attributes = clone_attributes
		}
	end
	if existing then
		if #self.items >= self.stack_limit then return end
		local delta = self.items[i].stack + item_definition.stack
		if delta > self.stack_limit then
			if #self.items+1 >= self.stack_limit then return end
			_add_item(delta-self.stack_limit)
		end
		self.items[i].stack = math.min(self.stack_limit,
			delta
		)

	else
		_add_item()
	end
end
--[[
	the inventory:remove_item(index|name) method is used to remove items. If a string value was passed
	as an argument it will go through inventory.items table and finding which is equal to that string value
	and if found, will be removed. Or if a number value was passed it will remove the item that holds the index.
]]
function api.inv_system:remove_item(idx)
	assert(type(idx) == "string" or type(idx) == "number",
		("Expected a number for idx removing or a string for removing by name, not \"%s\""):format(type(idx))
	)
	if type(idx) == "string" then
		local i,existing = self:find(function(item) return item.name == idx end)
		if existing then
			table.remove(self.items,i)
		end
	else
		table.remove(self.items,idx)
	end
end
--[[
	the api.inv_system:new(table|nil) method is used to create tables that has inherited the api.inv_system table.
	if a table was passed, it will inherit the api.inv_system table to that. If no arguments were passed, it will
	make a table that will be inherited by the api.inv_system table.
]]
function api.inv_system:new(table)
	return setmetatable(
		table or {items={},stack_limit=128,can_fit=9},
		{__index=self}
	)
end

--[[
	api.register_machine(id,definition) registers machines. duh. but you may be wondering what you have to do to make a proper machine. well here we go!
	{
		type = "machine", -- this determines what type it is, if it's machine, it'll be an average machine that needs a switch at its left and a storage at its right.
		-- if it's switch, it'll be used as a switch! machines will use the switch at the left in order to get power
		-- if it's storage, it will hold its own inventory and other machines at its left could put items inside of it!
		-- if user right clicks on it, it will play a sound depending on the type, if its switch, it'll play "switch.wav" and if its storage, it'll play "storage.wav"
		-- if the sound for its type doesn't exist, nothing will play
		
		switch_on = false, -- this is exclusive to the switch type, if true it will be able to be used by machines at the right to power on
		-- the user can right click on the switch type to toggle between true (ON) and false (OFF)

		pwr_on = false, -- exclusive to the machine type, if true it will be able to function. not sure what you expected
		
		extract = 3, -- if you want to make it an extractor you can add this key and set it to a number like 3 or 6, but keep it in the range where most deposits have
		
		on_update = function(self, grid, self_r, self_c)
			local right = grid[self_r][self_c+1] -- r = y axis, c = x axis
			local above = grid[self_r-1][self_c] -- r goes from top to bottom, meaning r-1 is above and r+1 is below
			if right ~= 'e"' and right.type == "storage" then -- 'e"' is the symbol of an empty grid element. Why not nil? That is a mystery in it of itself
				right.storage:add_item(above:random_deposit_item(self.extract))
			end
		end, -- this is run every time the 5 second timer turns to 0 which is how the game progresses (for machine type, you must have pwr_on set to true)
	}

	You should make the id name something like "modname:my_cool_machine". That naming convention isn't required but try your best to make a name that
	doesn't conflict with other mods if installed
]]
function api.register_machine(machine_id,definition)
	registered_machines[machine_id] = definition 
end
--[[
	api.register_deposit(id,definition) registers deposits. These deposits hold items an extractor from below (or above) can extract for
	{
		type = "deposit", -- don't bother, it'll always be deposit no matter what type you enter
		name = "Insane Deposit", -- should describe what is different from other deposits in a title
		img_m = "deposit.png", -- get image, very cool
		items_table = {} -- should be an iterable of item tables, hardcoding items is not recommended. put it in a variable
		-- or like an iterable, call it mymod_items or whatever you wanna name it
	}
]]
function api.register_deposit(deposit_id,definition)
	definition.type = "deposit"
	registered_deposits[deposit_id] = definition
end

--[[
	api.register_section(section_name) registers sections player can go to using one of the buttons on the toolbar. 
	The section_name is also responsible for grabbing the icon. If the icon doesn't exist anywhere in the "icons/" directory,
	it'll show a question mark instead called "nil.png". Since you can't like, import your own images without mutating the original directory
	goodluck with finding which one's which!
]]
function api.register_section(section_name)
	registered_sections[#registered_sections+1]= section_name
end

--[[
	api.dpcopy(table) isn't necessarily related to the game, but can be handy for certain situations, whenever you want to clone a table. No shallow, deep,
]]
function api.dpcopy(t)
	-- Recursive cloning is happening here
	if type(t)~="table"then return t end
	local clone={}
	for k,v in pairs(t)do clone[k]=api.dpcopy(v)end
	return setmetatable(clone,getmetatable(t))
end

--[[
	api.place("machine"|"deposit",grid,machine_id,rc_table,c) places a machine! if rc_table is a number, it'll be passed as the row, requiring fifth argument, which will be passed as column
	rc_table has the key "r" for row (or y axis) and "c" or column (or x axis)

	grid is usually passed as an argument from your "init(grid,api)" function.
	make sure grid[r][c] is 'e"' or you will replace something!
]]
function api.place(type_,grid,machine_id,rc_table,c)
	assert(type_=="machine"or type_=="deposit",
		"First argument must be a string with value \"machine\" or \"deposit\""
	)
	local r
	if type(rc_table)=="table" then
		r = rc_table.r or 0
		c = rc_table.c or 0
	else
		assert(type(rc_table)=="number",
			"4th argument must be a table or number"
		)
		assert(c,
			"5th argument must be passed"
		)
		r = rc_table
		c = c
	end
	local t
	if type_=="machine" then
		t = api.dpcopy(registered_machines[machine_id])
	else
		t = api.dpcopy(registered_deposits[machine_id])
	end
	grid[r][c] = t

end

function api.get_registered(type_)
	assert(type_=="machine"or type_=="deposit",
		"First argument must be a string with value \"machine\" or \"deposit\""
	)
	if type_=="machine" then
		return registered_machines
	else
		return registered_deposits
	end
end
function api.get_registered_sections()
	return registered_sections
end
function api.add_section_table_for(name)
	function test()
		for _,sname in ipairs(registered_sections) do
			if sname == name then return true end
		end
		return false
	end
	assert(test(),
		"Make sure the section is registered using register_section!"
	)
	api.sections[name] = {}
end
-- deprecated way to get sections
function api.section_tables()
	return api.sections
end

function api.add_machine_to_shop(id)
	api.shop_machines[#api.shop_machines+1]= id
end

