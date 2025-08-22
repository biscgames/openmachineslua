local soundq = require "modules.soundq"

local background_color = {0.302,0.506,0.741}
local section_background_color = {0.14,0.14,0.14}

local toolbar_background_color = {0.91,0.973,1}
local selected_icon_background_color = {0.365,0.58,0.922}
local toolbar_y = 0
local toolbar_height = 100
local first_section_btn_x = 32
local section_btn_spacing = 8

local images = {}
local audio = {}
for _,folder in ipairs({"icons","machines","states","items"}) do
	for _,fname in ipairs(love.filesystem.getDirectoryItems(folder)) do
		local dir = folder.."/"..fname
		images[fname] = love.graphics.newImage(dir)
		images[fname]:setFilter("nearest","nearest")
	end
end
for _,fname in ipairs(love.filesystem.getDirectoryItems("sounds")) do
	local dir = "sounds/"..fname
	audio[fname] = love.audio.newSource(dir,"static")
end

local section = "machines"
local section_buttons = {
	"new_machine",
	"machines",
	"settings",
	"inventory"
}
local sections = {}
for _,s in ipairs(section_buttons) do
	sections[s] = {}
end

local machines_grid = {}
for r=1,6 do
	local row = {}
	for c=1,12 do
		row[c] = 'e"'
	end
	machines_grid[r] = row
end
math.randomseed(os.time())
for t=1,3 do
	for _=1,3 do math.random() end
	local r = math.random(2,#machines_grid-1)
	local c = math.random(2,#machines_grid[r]-1)
	machines_grid[r][c] = {
		name = "Normal Deposit",
		type = "deposit",
		img_m = "deposit.png"
	}
end
local deposit_items = {
	{name="Iron",stack=4,image="iron.png"},
	{name="Gold",stack=2,image="gold.png"},
	{name="Etherium",stack=1,image="eth.png"}
}

local selected = {x=0,y=0}
local inventory = {}

local stack_limit = 128

inventory.__index = inventory
inventory.can_fit = 9
inventory.items = {}
function inventory:find(func)
	for i,item in ipairs(self.items) do
		if func(item,i) then return i,item end
	end
	return nil,nil
end
function inventory:add_item(item,stack)
	local image
	local itemname
	if type(item) == "table" then
		image = item.image
		stack = item.stack
		itemname = item.name
	else
		itemname = item
	end
	stack = tonumber(stack) or 0
	local i,existing = self:find(function(test) return test.name == itemname and test.stack < stack_limit end)
	if not existing then
		if #self.items>=self.can_fit then return end
		self.items[#self.items+1] = {
			name = itemname,
			stack = stack,
			image = image
		}
		return
	end
	local add_by = self.items[i].stack+stack
	self.items[i].stack = math.min(stack_limit,add_by)
	if self.items[i].stack+stack > stack_limit then
		if math.abs(stack_limit-add_by)<1 then return end
		self.items[#self.items+1] = {
			name = itemname,
			stack = math.abs(stack_limit-add_by),
			image = image
		}
	end

end
function inventory:remove_item(idx)
	table.remove(self.items,idx)
end
function inventory.new(can_fit)
	return setmetatable({items={},can_fit=can_fit},inventory)
end

local font = love.graphics.newFont("fonts/font.ttf",24)

function love.load() 
	love.graphics.setFont(font)
	local bgm = love.audio.newSource("bgm/Hypnothis.mp3","stream")
	bgm:setVolume(0.25)
	bgm:setLooping(true)
	bgm:play()
end
function love.mousepressed(mx,my,button)
	if sections[section] then
		if sections[section].mousepressed then
			sections[section]:mousepressed(mx,my,button)
		end
	end
	if my > toolbar_y+toolbar_height or button ~= 1 then return end
	for i=1,#section_buttons do
		local btn = section_buttons[i]
		local img = images[btn..".png"] or images["nil.png"]
		local x = first_section_btn_x+((i-1)*(img:getWidth()+section_btn_spacing))
		local y = toolbar_y+(img:getHeight()-toolbar_height/2)

		local colliding_x = mx > x-img:getWidth() and mx < x+img:getWidth()
		local colliding_y = my > y-img:getHeight() and my < y+img:getHeight()
		if colliding_x and colliding_y then
			soundq.pushqueue(audio["click.wav"])
			section = btn
			break
		end
	end
end
function love.mousereleased(mx,my,button)
	if sections[section] then
		if sections[section].mousereleased then
			sections[section]:mousereleased(mx,my,button)
		end
	end
end

local selection_mode = false
function love.draw()
	love.graphics.setBackgroundColor(section_background_color)

	love.graphics.setColor(toolbar_background_color)
	love.graphics.rectangle(
		"fill",
		0,toolbar_y,
		love.graphics.getWidth(),toolbar_height
	)
	if not selection_mode then
		for i=1,#section_buttons do
			local btn = section_buttons[i]
			local img = images[btn..".png"] or images["nil.png"]
			local x = first_section_btn_x+((i-1)*(img:getWidth()+section_btn_spacing))
			local y = toolbar_y+((img:getHeight()-toolbar_height/2))
			if section == btn then
				love.graphics.setColor(selected_icon_background_color)
				love.graphics.rectangle(
					"fill",
					x,y,
					img:getWidth(),img:getHeight(),
					16,16
				)
			end
			love.graphics.setColor(toolbar_background_color)
			love.graphics.draw(
				img,
				x,y
			)
		end
	else
		love.graphics.setColor(0,0,0)
		love.graphics.print("You are in select mode. Press escape or select a grid element to leave")
		love.graphics.setColor(1,1,1)
	end
	if sections[section] then
		if sections[section].draw then
			sections[section]:draw()
		end
	end
end
function love.keypressed(key)
	if sections[section] then
		if sections[section].keypressed then
			sections[section]:keypressed(key)
		end
	end
end
function love.update(dt)
	soundq.playqueue()
	if sections[section] then
		if sections[section].update then
			sections[section]:update(dt)
		end
	end
end

sections.machines.theme = {}
sections.machines.theme.scale_factor = 0.5
sections.machines.theme.revolve_around_x = love.graphics.getWidth()/2
sections.machines.theme.revolve_around_y = love.graphics.getHeight()/2
sections.machines.tick = 5

function sections.machines:draw()
	love.graphics.setBackgroundColor(background_color)

	love.graphics.setColor(0,0,0)
	love.graphics.print(math.floor(self.tick+0.5),0,0)
	love.graphics.setColor(toolbar_background_color)
	local theme = self.theme
	local rx = theme.revolve_around_x
	local ry = theme.revolve_around_y
	for r=1,#machines_grid do
		for c=1,#machines_grid[r] do
			local tile = machines_grid[r][c]
			local img
			if tile ~= 'e"' then
				img = images[tile.img_m or "nil_machine.png"]
			else
				img = images["edblquote.png"]
			end
			local tile_w = img:getWidth()*theme.scale_factor
			local tile_h = img:getHeight()*theme.scale_factor
			local x = (rx-(((#machines_grid[r])/2)*tile_w))+((c-1)*tile_w)
			local y = (ry-(((#machines_grid)/2)*tile_h))+((r-1)*tile_h)
			if tile ~= 'e"' or selection_mode then
				love.graphics.draw(
					img,
					x,y,
					0,theme.scale_factor
				)
			end
			if tile ~= 'e"' then
				if tile.type == "machine" then
					if not tile.pwr_on then
						love.graphics.draw(
							images["red_state.png"],
							x,y,
							0,theme.scale_factor
						)
					elseif not tile.has_storage then
						love.graphics.draw(
							images["orange_state.png"],
							x,y,
							0,theme.scale_factor
						)
					end
				elseif tile.type == "storage" then
					if tile.storage.items and #tile.storage.items>0 then
						local biggest_item_stack = {stack=0}
						tile.storage:find(function(item)
							if (item.stack or 0)>biggest_item_stack.stack then
								biggest_item_stack = item
							end
						end)
						if biggest_item_stack.image then
							love.graphics.draw(
								images[biggest_item_stack.image],
								x,y,
								0,theme.scale_factor
							)
						end
						love.graphics.print(
							tostring(biggest_item_stack.stack),
							x+25,y+25
						)
					end
				end
			end
		end
	end
	if not self.machine_hover then return end
	local mx,my = love.mouse.getPosition()
	local rectx
	local recty
	recty = my
	local rectw
	if self.machine_hover.extract then
		rectw = 400
	elseif self.machine_hover.type == "storage" then
		rectw = (self.machine_hover.storage.can_fit*(images[deposit_items[1].image]:getWidth()*theme.scale_factor))+16
	else
		rectw = 200
	end
	if mx-(love.graphics.getWidth()/2)>0 then
		rectx = mx-rectw
	else
		rectx = mx
	end
	love.graphics.setColor(toolbar_background_color)
	love.graphics.rectangle(
		"fill",
		rectx,recty,
		rectw,100,
		16
	)
	love.graphics.setColor(0,0,0)
	if self.machine_hover.type == "switch" then
		local text = self.machine_hover.switch_on and "ON" or "OFF"
		local font = love.graphics.getFont()
		local font_w = font:getWidth(text)
		local font_h = font:getHeight()
		love.graphics.print(
			text,
			rectx+(rectw-font_w)/2,
			recty+(100-font_h)/2
		)
	elseif self.machine_hover.type == "storage" then
		local storage = self.machine_hover.storage
		if not storage.items then return end
		for i,item in ipairs(storage.items) do
			local img = images[item.image]
			local x = 16+((i-1)*(img:getWidth()*theme.scale_factor))
			local tile_h = img:getHeight()*theme.scale_factor
			love.graphics.setColor(1,1,1)
			love.graphics.draw(
				img,
				rectx+x,
				recty+((100-tile_h)/2),
				0,theme.scale_factor
			)
			love.graphics.setColor(0,0,0)
			love.graphics.print(
				tostring(item.stack),
				rectx+(x+25),
				recty+((100-tile_h)/2)+25
			)
			love.graphics.setColor(toolbar_background_color)
		end
	elseif self.machine_hover.extract then
		local text
		if not self.machine_hover.pwr_on then
			text = "Needs an activated switch at the left"
		elseif not self.machine_hover.has_storage then
			text = "Needs storage at the right"
		elseif not self.machine_hover.touching_deposit then
			text = "Needs deposit above (or below if advanced)"
		else
			text = "Should extract items to storage at the right"
		end
		local font = love.graphics.getFont()
		love.graphics.print(
			text,
			rectx+((rectw-font:getWidth(text))/2),
			recty+((100-font:getHeight())/2)
		)
	end
	love.graphics.setColor(1,1,1)
	-- Placeholder
	--love.graphics.rectangle(
	--	"fill",
	--	(love.graphics.getWidth()-100)/2,(love.graphics.getHeight()-100)/2,
	--	100,100,
	--	16,16
	--)
end
sections.machines.machine_hover = nil
function sections.machines:update(dt)
	local function iterate(func)
		for r=1,#machines_grid do
			for c=1,#machines_grid[r] do
				func(r,c,machines_grid[r][c])
			end
		end
	end
	local function update_machine(r,c)
		local machine = machines_grid[r][c]
		if machine == 'e"' then return end
		local machine_left = machines_grid[r][c-1] or 'e"'
		local machine_right = machines_grid[r][c+1] or 'e"'
		local grid_below = machines_grid[r+1] and machines_grid[r+1][c] and machines_grid[r+1][c] or 'e"'
		local grid_above = machines_grid[r-1] and machines_grid[r-1][c] and machines_grid[r-1][c] or 'e"'
		if machine_left == 'e"' or not machine_left.switch_on then
			machine.pwr_on = false
		elseif machine_left.switch_on then
			machine.pwr_on = true
		end
		machine.has_storage = machine_right ~= 'e"' and machine_right.type == "storage"

		if machine.pwr_on then
			if machine.extract and machine.has_storage then
				if grid_above ~= 'e"' and grid_above.type == "deposit" then
					machine.touching_deposit = true
					machine_right.storage:add_item(deposit_items[math.random(1,#deposit_items)])
					--machine_right.storage:add_item({
					--	name = "Testificate",
					--	stack = 1,
					--	image = "testificate.png"
					--})
				end
				if grid_below ~= 'e"' and grid_below.type == "deposit" and machine.extract_below then
					machine.touching_deposit = true
					machine_right.storage:add_item(deposit_items[math.random(1,#deposit_items)])
					--machine_right.storage:add_item({
					--	name = "Testificate",
					--	stack = 1,
					--	image = "testificate.png"
					--})
				end
				if (grid_below == 'e"' or grid_below.type ~= "deposit") or (grid_above == 'e"' or not grid_above.type ~= "deposit") then
					machine.touching_deposit = false
				end
			end
		end
	end
	local function update_machines()
		iterate(update_machine)
	end
	self.tick=self.tick-dt
	if self.tick<=0 then
		self.tick = 5
		update_machines()
	end
	
	local theme = self.theme
	local rx = theme.revolve_around_x
	local ry = theme.revolve_around_y

	local mx,my = love.mouse.getPosition()
	local machine_hovered = false
	iterate(function(r,c,m)
		local img = images["edblquote.png"]
		local tile_w = img:getWidth()*theme.scale_factor
		local tile_h = img:getHeight()*theme.scale_factor
		local x = (rx-(((#machines_grid[r])/2)*tile_w))+((c-1)*tile_w)
		local y = (ry-(((#machines_grid)/2)*tile_w))+((r-1)*tile_h)
		local colliding_x = mx>x and mx<x+tile_w
		local colliding_y = my>y and my<y+tile_h
		if colliding_x and colliding_y and m ~= 'e"' then
			machine_hovered = true
			self.machine_hover = m
		end
	end)
	if not machine_hovered then
		self.machine_hover = nil
	end
end

sections.machines.sounds = {}
sections.machines.sounds.select = audio["select.wav"]
sections.machines.sounds.place = audio["place.wav"]
function sections.machines:mousereleased(mx,my,button)
	local theme = self.theme
	local rx = theme.revolve_around_x
	local ry = theme.revolve_around_y
	for r=1,#machines_grid do
		for c=1,#machines_grid[r] do
			local tile = machines_grid[r][c]
			local img
			img = images["edblquote.png"]
			local tile_w = img:getWidth()*theme.scale_factor
			local tile_h = img:getHeight()*theme.scale_factor
			local x = (rx-(((#machines_grid[r])/2)*tile_w))+((c-1)*tile_w)
			local y = (ry-(((#machines_grid)/2)*tile_h))+((r-1)*tile_h)

			local colliding_x = mx>x and mx<x+tile_w
			local colliding_y = my>y and my<y+tile_h

			if colliding_x and colliding_y then
				if button == 1 then
					selected.x = c
					selected.y = r
					if selection_mode then
						if tile == 'e"' then
							section = "new_machine"
							soundq.pushqueue(self.sounds.place)
							love.timer.sleep(0.02) -- VERY IMPORTANT, DO NOT REMOVE
							sections.new_machine:mousereleased(mx,my)
						end
					else
						soundq.pushqueue(self.sounds.select)
					end
				elseif button == 2 then
					if tile ~= 'e"' then
						if tile.switch_on ~= nil then
							tile.switch_on = not tile.switch_on
						elseif tile.type == "storage" then
							while #tile.storage.items > 0 do
								local item = tile.storage.items[1]
								inventory:add_item(item)
								table.remove(tile.storage.items,1)
							end
						end
						if audio[tile.type..".wav"] then
							soundq.pushqueue(audio[tile.type..".wav"])
						end
					end
				else
					machines_grid[r][c] = 'e"'
				end
			end
		end
	end

end
function sections.machines:keypressed(key)
	if key == "escape" and selection_mode then
		selection_mode = false
		sections.new_machine.select_idx = 0
		section = "new_machine"
	end
end

sections.new_machine.theme = {}
sections.new_machine.theme.first_button_y = 8 -- Relative to toolbar_y+toolbar_height
sections.new_machine.theme.button_height = 64
sections.new_machine.theme.button_spacing = 8
sections.new_machine.theme.button_background_color = toolbar_background_color
sections.new_machine.theme.button_image_x = 16
sections.new_machine.theme.machine_image_scale_factor = 0.35

sections.new_machine.machines = {
	{name="Switch",type="switch",img_m="switch_machine.png",switch_on=false},
	{name="Extractor",type="machine",img_m="extractor.png",extract=3,pwr_on=false,has_storage=false,extract_below=false},
	{name="Advanced Extractor",type="machine",img_m="advanced_extractor.png",extract=3,pwr_on=false,has_storage=false,extract_below=true},
	{name="Simple Storage",type="storage",img_m="simple_storage.png",can_fit=1,storage={}},
	{name="Storage",type="storage",img_m="storage_machine.png",can_fit=3,storage={}},
}
function sections.new_machine:draw()
	local theme = self.theme
	for i,machine in ipairs(self.machines) do
		if self.select_idx == i then
			love.graphics.setColor(selected_icon_background_color)
		else
			love.graphics.setColor(toolbar_background_color)
		end
		local toolbar_relative = toolbar_y+toolbar_height
		local y = (theme.first_button_y+toolbar_relative)+((i-1)*(theme.button_height+theme.button_spacing))
		love.graphics.rectangle(
			"fill",
			0,y,
			love.graphics.getWidth(),theme.button_height
		)
		local img = images[machine.type..".png"]
		love.graphics.draw(
			img,
			theme.button_image_x,y+(theme.button_height-img:getHeight())/2
		)
		local mimg = images[machine.img_m or "nil.png"]
		love.graphics.draw(
			mimg,
			love.graphics.getWidth()-(mimg:getWidth())-theme.button_image_x,
			y+(theme.button_height-(mimg:getHeight()*theme.machine_image_scale_factor))/2,
			0,theme.machine_image_scale_factor
		)

		love.graphics.setColor(0,0,0)
		local font = love.graphics.getFont()
		local font_w = font:getWidth(machine.name)
		local font_h = font:getHeight()
		love.graphics.print(
			machine.name,
			(love.graphics.getWidth()-font_w)/2,
			y+((theme.button_height-font_h)/2)
		)
	end
	-- Placeholder
	-- love.graphics.print("Nothing here! - new_machine",0,toolbar_y+toolbar_height)
end
sections.new_machine.selected_machine_here = false
sections.new_machine.select_idx = 0
function sections.new_machine:mousepressed(mx,my,button)
	if button ~= 1 then return end
	local theme = self.theme
	for i,machine in ipairs(self.machines) do
		local toolbar_relative = toolbar_y+toolbar_height
		local y = (theme.first_button_y+toolbar_relative)+((i-1)*(theme.button_height+theme.button_spacing))
		if my > y and my < y+theme.button_height then
			self.select_idx = i
			break
		end
	end
	if self.select_idx<1 then return end
	self.selected_machine_here = true
end
function sections.new_machine:mousereleased(mx,my)
	mx=mx or 0
	my=my or 0
	local reachable = my>self.theme.first_button_y+toolbar_y+toolbar_height
	if not reachable then return end
	if not self.selected_machine_here then return end
	if (selected.x<1 and selected.y<1) or (machines_grid[selected.y][selected.x] ~= 'e"') then
		selection_mode = true
		section = "machines"
	else
		local function clone_table(t)
			if type(t) ~= "table" then return t end
			local clone_t = {}
			for k,v in pairs(t) do
				clone_t[clone_table(k)]=clone_table(v)
			end
			return clone_t
		end
		for i,machine in ipairs(self.machines) do
			if self.select_idx==i then
				machines_grid[selected.y][selected.x] = clone_table(machine)
				if machines_grid[selected.y][selected.x].storage then
					machines_grid[selected.y][selected.x].storage = inventory.new(machine.can_fit)
				end
				break
			end
		end
		self.selected_machine_here = false
		self.select_idx = 0
		selected.x = 0
		selected.y = 0
		if selection_mode then
			selection_mode = false
		end
	end
end

function sections.settings:draw()
	-- Placeholder
	love.graphics.print("Nothing here! - settings",0,toolbar_y+toolbar_height)
end

sections.inventory.scale_factor = 0.75
function sections.inventory:draw()
	local relative = toolbar_y+toolbar_height
	for i,item in ipairs(inventory.items) do
		love.graphics.draw(
			images[item.image],
			(i-1)*(images[item.image]:getWidth()*self.scale_factor),
			relative,
			0,self.scale_factor
		)
		love.graphics.print(
			item.stack,
			(i-1)*(images[item.image]:getWidth()*self.scale_factor)+25,
			relative+25
		)
	end
end
