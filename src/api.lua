api = {}
local registered_deposits = {}
local registered_machines = {}

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
		item.name==item_definition.name and item.stack<self.stack_limit 
	end)
	local function _add_item(stack)
		stack = stack or item_definition.stack
		local clone_attributes = {}
		for k,v in pairs(item_definition.attributes or {}) do
			if type(v) ~= "table" then clone_attributes[k] = v end
		end
		self.items[#self.items+1]= {
			name = item_definition.name,
			stack = stack,
			image = item_definition.image,
			attributes = clone_attributes
		}
	end
	if existing then
		local delta = self.items[i].stack + item_definition.stack
		self.items[i].stack = math.min(self.stack_limit,
			delta
		)
		if delta > self.stack_limit then
			_add_item(delta-self.stack_limit)
		end
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
		i,existing = self:find(function(item) item.name == idx end)
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
		self
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
]]
function api.register_machine(machine_id,definition)
	registered_machines[machine_id] = definition 
end
function api.register_deposit(deposit_id,definition)
	definition.type = "deposit"
	registered_deposits[deposit_id] = definition
end
