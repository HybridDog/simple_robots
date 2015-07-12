--Copyright 2014 gamemanj
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
--
--tiers.lua: Robot types and recipes.

simple_robots.register_robot_type(
    --node name
    "simple_robots:robot_simple",
    --description
    "Simple Robot",
    --nodebox when off
    {
        type = "fixed",
        fixed = {
            {-0.5, -0.375, -0.4375, 0.5, -0.1875, 0.5}, -- NodeBox1
            {-0.4375, -0.4375, -0.4375, 0.4375, -0.375, 0.4375}, -- NodeBox2
            {-0.375, -0.5, -0.375, 0.375, -0.4375, 0.375}, -- NodeBox3
            {-0.5, -0.1875, -0.5, -0.375, 0.25, 0.5}, -- NodeBox4
            {-0.5, 0.25, -0.5, 0.5, 0.3125, 0.5}, -- NodeBox5
            {0.375, -0.1875, -0.5, 0.5, 0.25, 0.5}, -- NodeBox6
            {-0.4375, 0.3125, -0.4375, 0.4375, 0.375, 0.4375}, -- NodeBox7
            {-0.375, -0.1875, -0.375, 0.375, 0.25, 0.5}, -- NodeBox8
            {-0.5, -0.375, -0.5, 0.5, -0.3125, -0.4375}, -- NodeBox9
            {-0.5, -0.25, -0.5, 0.5, -0.1875, -0.4375}, -- NodeBox10
            {-0.5, -0.3125, -0.5, 0.0625, -0.25, -0.4375}, -- NodeBox11
            {0.375, -0.3125, -0.5, 0.5, -0.25, -0.4375}, -- NodeBox12
        }
    },
    --tex_on
    {"simple_robots_robot_on_top.png",
        "simple_robots_robot_bottom.png",
        "simple_robots_robot_side.png",
        "simple_robots_robot_side.png",
        "simple_robots_robot_back.png",
        "simple_robots_simple_front.png"
    },
    --tex_off
    {"simple_robots_robot_off_top.png",
        "simple_robots_robot_bottom.png",
        "simple_robots_robot_side.png",
        "simple_robots_robot_side.png",
        "simple_robots_robot_back.png",
        "simple_robots_off_front.png"},
    {"scout","miner","builder","inventory"}
)

minetest.register_craft({
	output = 'simple_robots:robot_simple_off',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:glass', 'default:mese_crystal', 'group:stick'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})
