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
--page_miner.lua:MINER PAGE

--MINER PAGE

local MINEPENALTYTIME=0 --Extra time needed to mine a block(a robot penalty if you will)
local PUNCHTIME=0.5 --Time taken to punch.

--"MINE ELSE GOTO" "MINE UP ELSE GOTO" "MINE DOWN ELSE GOTO"

-- gets the dug sound of a node
local function vm_get_node_dug_sound(name)
    local sound = minetest.registered_nodes[name]
    if not sound then
        return
    end
    sound = sound.sounds
    if not sound then
        return
    end
    sound = sound.dug
    if not sound then
        return
    end
    return sound
end

local function vm_mine(pos1,dir,arg)
    local meta=minetest.get_meta(pos1)
    local pos2=vector.add(pos1,dir)
    local node=minetest.get_node(pos2)
    if simple_robots.vm_is_air(node) then return simple_robots.vm_lookup(pos1,arg,0) end
    --For some insane reason,
    --this has to try both the current tool and the hand to find which is better.
    --For example,I can use a stone pickaxe to dig dirt.
    --But I can't do so DIRECTLY. I have to use the hand.
    local dp_pool={}--Pool of "potential" digparams.
    local dp_result=nil--Result.
    --Hand.(For some reason this must be included
    --      or it becomes inconsistent with players)
    local toolcaps = ItemStack({name=":"}):get_tool_capabilities()
    table.insert(dp_pool,minetest.get_dig_params(ItemStack({name=node.name}):get_definition().groups, toolcaps))
    --Tool.
    toolcaps = simple_robots.vm_get_wielded(pos1):get_tool_capabilities()
    table.insert(dp_pool,minetest.get_dig_params(ItemStack({name=node.name}):get_definition().groups, toolcaps))
    for k,v in ipairs(dp_pool) do
        --get_dig_params is undocumented @ wiki,but it works.
        --time:float,diggable:boolean
        if v.diggable then
            if dp_result==nil then
                dp_result=v
            else
                --Compare,to find the most time-efficient dig method.
                if dp_result.time>v.time then
                    dp_result=v
                end
            end
        end
    end
    --Check if unable to dig!
    if not dp_result then return simple_robots.vm_lookup(pos1,arg,0) end
    local fp=simple_robots.vm_fakeplayer(meta:get_string("robot_owner"),pos1,{sneak=false},meta:get_int("robot_slot"))
    if not fp then return simple_robots.vm_lookup(pos1,arg,0) end
    minetest.registered_nodes[node.name].on_dig(pos2, node, fp)
    fp:remove()
    --The block not being air is considered "failure".
    --HOWEVER,since the dig itself was a success,it takes time.
    if (not simple_robots.vm_is_air(minetest.get_node(pos2))) then return simple_robots.vm_lookup(pos1,arg,dp_result.time+MINEPENALTYTIME) end

    local sound = vm_get_node_dug_sound(node.name)
    if sound then
        minetest.sound_play(sound.name, {pos=pos2, gain=sound.gain})
    end
    
    return simple_robots.vm_advance(pos1,dp_result.time+MINEPENALTYTIME)
end

simple_robots.commands["MINE ELSE GOTO"]=function (pos,arg)
    return vm_mine(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
end
simple_robots.commands["MINE UP ELSE GOTO"]=function (pos,arg)
    return vm_mine(pos,{x=0,y=1,z=0},arg)
end
simple_robots.commands["MINE DOWN ELSE GOTO"]=function (pos,arg)
    return vm_mine(pos,{x=0,y=-1,z=0},arg)
end

--"PUNCH ELSE GOTO" "PUNCH UP ELSE GOTO" "PUNCH DOWN ELSE GOTO"

--NOTE:This handles both the use of a tool and the punch itself.
local function vm_punch(pos1,dir,arg)
    local meta=minetest.get_meta(pos1)
    local pos2=vector.add(pos1,dir)
    local node=minetest.get_node(pos2)
    local fp=simple_robots.vm_fakeplayer(meta:get_string("robot_owner"),pos1,{sneak=false},meta:get_int("robot_slot"))
    local stk=meta:get_inventory():get_stack("main",meta:get_int("robot_slot"))
    if not fp then return simple_robots.vm_lookup(pos1,arg,0) end
    local success=false
    local pointedthing={type="nothing"}
    if (not simple_robots.vm_is_air(node)) then
        pointedthing={type="node",above=pos1,under=pos2}
        minetest.registered_nodes[node.name].on_punch(pos2, node, fp,pointedthing)
        success=true
    end
    if stk:get_definition().on_use then
        local is=stk:get_definition().on_use(stk, fp,pointedthing)
        if is~=nil then
            meta:get_inventory():set_stack("main",meta:get_int("robot_slot"),is)
        end
        success=true
    end
    fp:remove()
    if not success then return simple_robots.vm_lookup(pos1,arg,0) end
    return simple_robots.vm_advance(pos1,PUNCHTIME)
end

simple_robots.commands["PUNCH ELSE GOTO"]=function (pos,arg)
    return vm_punch(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
end
simple_robots.commands["PUNCH UP ELSE GOTO"]=function (pos,arg)
    return vm_punch(pos,{x=0,y=1,z=0},arg)
end
simple_robots.commands["PUNCH DOWN ELSE GOTO"]=function (pos,arg)
    return vm_punch(pos,{x=0,y=-1,z=0},arg)
end

--PAGE DEFINITION

simple_robots.commandpages["miner"]={"MINE ELSE GOTO","MINE UP ELSE GOTO","MINE DOWN ELSE GOTO","PUNCH ELSE GOTO","PUNCH UP ELSE GOTO","PUNCH DOWN ELSE GOTO"}

