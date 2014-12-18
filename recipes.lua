local MOD_NAME=({...})[1]
minetest.register_craft({
	output = MOD_NAME..':robot_simple_off',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:glass', 'default:mese_crystal', 'group:stick'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})
