# API For Modders
The API is very simple, though limiting it does the job done, if this hasn't explained enough, the api.lua file is full of comments explaining functions!</br>
Mods are located at:
- Windows: C:/Users/<YOUR USERNAME\>/AppData/Roaming/LOVE/OpenMachinesLua/mods
- Linux: ~/.local/share/love/OpenMachinesLua/mods
- Android: /data/data/org.love2d.android/files/save/OpenMachinesLua/mods
- macOS: /Users/<YOUR USERNAME\>/Library/Application Support/LOVE/OpenMachinesLua/mods
<br/>
The game already creates the mods folder there, don't bother<br/>
<br/>
Your mod can either be a lua file, or a folder containing init.lua (for custom textures, the folder approach is superior)<br/>
Now, the game expects the lua file to return a function. There are two ways to do this.

```lua

-- Creating function init, then returning it
function init(grid,api)
	print("Hello, World:)")
end
return init

-- Directly returning a function
return function(grid,api)
	print("Hello, World:)")
end

```

You've might've noticed the 2 arguments, grid and api. These two are passed by the game, the first argument is the world grid that your game has. The second argument is the api itself.

## Machines
Excited to make your first machine? I sure am not. The way to register machines is by using `api.register_machine(id,definition)`.
First let's go through what makes a definition a definition:
```lua
{
	name = "Hello, World!", -- A short description, shown by the shop at new_machine section
	type = "machine", -- there are 3 types to choose from. machine, storage and switch.
	on_update = function(self,grid,) -- Remember, machine types must have an activated switch at its left in order for this to activate every 5 seconds
		-- This example prints "Hello, World!" to the console
		print("Hello, World!")
	end,
	img_m = "extractor.png", -- the image for the machine

	-- machine type exclusive
	pwr_on = false, -- this is usually true when there is an activated switch at the left.

	-- switch type exclusive
	switch_on = false, -- can be toggled by the user by right-clicking. usually false by default
}
```
This can later be added to the shop by using `api.add_machine_to_shop(id)`
I will use the naming convention "helloworldmod:helloworld_machine". It's not required but you should at least make your own to prevent mod conflicts. We hate mod conflicts don't we?</br>
Here's a mod i created

```lua
local helloworld_machine_definition = {
	name = "Hello, World!",
	type = "machine",
	img_m = "extractor.png", -- the image for the machine
	on_update = function(self,grid,)
		print("Hello, World!")
	end,
	pwr_on = false
}
function init(grid,api)
	api.register_machine("helloworldmod:helloworld_machine",helloworld_machine_definition)
	api.add_machine_to_shop("helloworldmod:helloworld_machine")
end
return init
```

## Items
Now, there isn't a direct way to "register" items. You can simply create an item by making a table. Like this:

```lua
{
	name = "Item Name", -- The name of your item
	stack = 10, -- The stack, must be more than 0 and less or equal to the average inventory stack limit
	image = "eth.png", -- Inventory image
	attributes = {} -- A list of attributes, if needed
}
```
Remember, it's not a good idea to hardcode items; put them in local variables.

## Deposits
Deposits are a way to obtain these items; to make one, just do this:

```lua
local helloworld_item = {
	name = "Hello, World!", -- The name of your item
	stack = 10, -- The stack, must be more than 0 and less or equal to the average inventory stack limit
	image = "eth.png", -- Inventory image
	attributes = {} -- A list of attributes, if needed
}
api.register_deposit("helloworldmod:helloworld_deposit",{
	name = "Hello, World Deposit",
	img_m = "deposit.png", -- the image of the deposit
	items_table = {helloworld_item} -- a list of items
})
```

## Inventory System
`api.inv_system` is a one-way ticket to implementing an inventory source onto a machine or anything really.
To create a new inventory, you can take the value of `api.inv_system:new({items={},can_fit=9})` and put it in a variable or anywhere that supports tables. Like this: 
```lua
local second_inventory = api.inv_system:new({
	items = {}, -- Iterable full of item resembling tables
	can_fit = 4, -- This is a limit of items that can be put in this inventory
	stack_limit = 128 -- A stack limit.
})
```

## Sections
Sections are a place navigated by a click of a button on the toolbar! To create a section you'll need to register it:

```lua
api.register_section("my_section")
```

then make a table for it:

```lua
api.add_section_table_for("my_section")
```

the game is created with love2d, using love2d's api you can draw anything you want

```lua
function init(grid,api)
	api.register_section("my_section")
	api.add_section_table_for("my_section")

	function api.sections.my_section:draw()
		local text = "Hello, World!:)"
		local f = love.graphics.getFont()
		local f_w = f:getWidth(text)
		local f_h = f:getHeight()
		love.graphics.print(text,
			(love.graphics.getWidth()-f_w)/2,
			(love.graphics.getHeight()-f_h)/2
		)
	end
end
return init
```
You can also detect mouse clicks by adding the function `api.sections.my_section:mousepressed(x,y,button)` or `api.sections.my_section:mousereleased(x,y,button)`. Updating is also easy, make the `api.sections.my_section:update(dt)` function!<br/>
Detecting keypresses can be done adding `api.sections.my_section:keypressed(key)`

the section button image always picks (section name).png. If it doesn't exist anywhere it will be a question mark
