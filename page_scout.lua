--Copyright 2014 gamemanj
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--	http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
--
--page_scout.lua:SCOUT PAGE

local MOVETIME=1 --Time taken to move.
local TURNTIME=1 --Time taken to turn.

--"NOP"

simple_robots.commands["NOP"] = function(pos,arg)
	return simple_robots.vm_advance(pos,0)
end

--GOTO

simple_robots.commands["GOTO"] = function(pos,arg)
	return simple_robots.vm_lookup(pos,arg,0)
end

--"TURN LEFT" "TURN RIGHT"

local function vm_turn(pos, dir)
	local ser = simple_robots.robot_to_table(pos)
	local node = minetest.get_node(pos)
	node.param2 = (node.param2+dir)%4
	minetest.set_node(pos, node)
	simple_robots.table_to_robot(pos, ser)
	return simple_robots.vm_advance(pos, TURNTIME)
end

simple_robots.commands["TURN LEFT"] = function(pos,arg)
	return vm_turn(pos,-1)
end

simple_robots.commands["TURN RIGHT"] = function(pos,arg)
	return vm_turn(pos,1)
end

--"FORWARD ELSE GOTO" "UPWARD ELSE GOTO" "DOWNWARD ELSE GOTO"

local function vm_tp(pos1, dir, arg)
	local pos2 = vector.add(pos1, dir)
	local ser = simple_robots.robot_to_table(pos1)
	if not simple_robots.vm_can_add(ser.owner, pos2) then
		return simple_robots.vm_lookup(pos1, arg, 0)
	end
	minetest.set_node(pos2, minetest.get_node(pos1))
	minetest.remove_node(pos1)

	nodeupdate(pos1)
	nodeupdate(pos2)
	--NOTE:Meta is still for pos1 since both these calls use positions.
	simple_robots.table_to_robot(pos2, ser)
	local timerval = simple_robots.vm_advance(pos2, MOVETIME)
	if not timerval then
		return --If vm_advance caused a shutdown,then don't setup the timer.
	end
	minetest.get_node_timer(pos2):start(timerval)--Manually control the timer,since get_node_timer won't work.
	--The cycle loop is still looking at the old position,
	--so tell it not to mess with the air's node timer(not that it should have one)
end

simple_robots.commands["FORWARD ELSE GOTO"] = function(pos,arg)
	return vm_tp(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
end
simple_robots.commands["UPWARD ELSE GOTO"] = function(pos,arg)
	return vm_tp(pos,{x=0,y=1,z=0},arg)
end
simple_robots.commands["DOWNWARD ELSE GOTO"] = function(pos,arg)
	return vm_tp(pos,{x=0,y=-1,z=0},arg)
end

--PAGE DEFINITION

simple_robots.commandpages.scout = {"NOP","GOTO","FORWARD ELSE GOTO","TURN LEFT","TURN RIGHT","UPWARD ELSE GOTO","DOWNWARD ELSE GOTO"}

