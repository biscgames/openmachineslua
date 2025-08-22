return function(machines_grid,api)

local iron = {
	name = "Iron",
	image = "iron.png",
	stack = 4,
	attributes = {}
}
local gold = {
	name = "Gold",
	image = "gold.png",
	stack = 2,
	attributes = {}
}
local eth = {
	name = "Etherium",
	image = "eth.png",
	stack = 1,
	attributes = {}
}
local bone = {
	name = "Bone",
	image = "bone.png",
	stack = 1,
	attributes = {}
}
api.register_deposit("default:normaldeposit",{
	name = "Normal Deposit",
	img_m = "deposit.png",

	items_table = {
		iron,
		gold,
		eth
	}
})
api.register_deposit("default:bonedeposit",{
	name = "Bone Deposit",
	img_m = "bonedep.png",

	items_table = {bone}
})

math.randomseed(os.time())
for t=1,3 do
	for _=1,4 do math.random() end
	local r = math.random(2,#machines_grid-1)
	local c = math.random(2,#machines_grid[r]-1)
	local depname
	if math.random(0,100) > 75 then
		depname = "default:bonedeposit"
	else
		depname = "default:normaldeposit"
	end
	api.place("deposit",machines_grid,depname,{r=r,c=c})
end

end
