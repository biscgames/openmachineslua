return function(grid,api)

api.register_machine("default:simplestorage",{
	name = "Simple Storage",
	img_m = "simple_storage.png",
	type = "storage",

	storage = api.inv_system:new({items={},can_fit=1})
})
api.add_machine_to_shop("default:simplestorage")
api.register_machine("default:storage",{
	name = "Storage",
	img_m = "storage_machine.png",
	type = "storage",

	storage = api.inv_system:new({items={},can_fit=3})
})
api.add_machine_to_shop("default:storage")

end
