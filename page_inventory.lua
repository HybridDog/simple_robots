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
--page_inventory.lua:INVENTORY PAGE

--INVENTORY PAGE

local DEPOSITTIME=1 --Time taken for a DEPOSIT.Does not scale with items.
local RETRIEVETIME=1 --Time taken for a RETRIEVE.Does not scale with items.

--Get front inventory
local function vm_getfrontinv(meta,pos)
	--Okay,first:Is there a inventory in front of us with a sub-inventory called "main"?
	--If so,it's either another robot(wow,robot transport!),a chest,or a node breaker :)
	--None are any loss.
	--(Course,I have yet to handle the case of locked chests,or really any inventory permissions stuff.)
	local pos2=vector.add(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2))
	--Permissions check,and does a implict is_air test.(hence it exists)
	if not simple_robots.vm_can_remove(meta:get_string("robot_owner"),pos2) then return nil end
	local tgtmeta=minetest.get_meta(pos2)
	if not tgtmeta then
		return
	end
	local inv=tgtmeta:get_inventory()
	if not inv then return nil end
	if inv:get_size("main")<1 then return nil end
	return inv
end

--"SELECT SLOT"

simple_robots.commands["SELECT SLOT"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	local p=tonumber(arg)
	if p==nil then simple_robots.shutdownat(pos) return nil end
	if p<1 then simple_robots.shutdownat(pos) return nil end
	if p>16 then simple_robots.shutdownat(pos) return nil end
	meta:set_int("robot_slot",p)
	return simple_robots.vm_advance(pos,0)
end

--"DEPOSIT ALL BUT SELECTED ELSE GOTO" "DEPOSIT SELECTED ELSE GOTO"

local function vm_deposit(pos,slots)
	local meta=minetest.get_meta(pos)

	local my_inv=meta:get_inventory()
	local inv=vm_getfrontinv(meta,pos)
	if not inv then return simple_robots.vm_lookup(pos,arg,0) end
	local lookup=false
	for _,p in ipairs(slots) do
		local is=my_inv:get_stack("main", p)
		is=inv:add_item("main",is)
		if is~=nil then if not is:is_empty() then lookup=true end end
		my_inv:set_stack("main",p,is)
	end
	if lookup then
		return simple_robots.vm_lookup(pos,arg,DEPOSITTIME)
	end
	return simple_robots.vm_advance(pos,DEPOSITTIME)
end

--vm_retrieve_add:Basically InvRef:add_item,but limited to slots.
--				This modifies stack,so no return is needed.
--				If this is at least a partial success,it returns true.
--				(complete success can be inferred from stack:is_empty())
local function vm_retrieve_add(invref,slots,stack)
	local oldcount=stack:get_count()
	--Basically,go through each slot,subtract what we do manage to get in from stack.
	for k,v in ipairs(slots) do
		if stack:is_empty() then return true end --Return if empty.
		local tis=invref:get_stack("main",v)
		--add_item doesn't specify if metadata is added,even on a clear slot.
		--Just in case,if it's a clear slot,then why add_item?
		--Also handles possibility of tis being nil.
		if (tis==nil) or tis:is_empty() then
			invref:set_stack("main",v,stack)
			stack:clear()--entire stack was inserted.
			return true
		end
		stack=tis:add_item(stack)
		invref:set_stack("main",v,tis)
	end
	return oldcount>stack:get_count()
end

--Main retrieve command function.
--slots describes the amount of slots.
--If partial_success is set,then as long as at least 1 item is transferred,
--it will be considered a success.
local function vm_retrieve(pos,slots,partial_success)
	local meta=minetest.get_meta(pos)
	local my_inv=meta:get_inventory()
	local inv=vm_getfrontinv(meta,pos)
	if not inv then return simple_robots.vm_lookup(pos,arg,0) end
	local failure=partial_success
	for p=1,inv:get_size("main") do
		local is=inv:get_stack("main",p)
		if not is:is_empty() then
			local res=vm_retrieve_add(my_inv,slots,is)
			inv:set_stack("main",p,is)
			if partial_success then
				if res then failure=false end
			else
				if not is:is_empty() then failure=true end
			end
		end
	end
	--If a partial_success-type retrieval was a failure,then nothing was retrieved.
	if failure and partial_success then return simple_robots.vm_lookup(pos,arg,0) end
	--Otherwise,something may have been retrieved.
	if failure then return simple_robots.vm_lookup(pos,arg,RETRIEVETIME) end
	return simple_robots.vm_advance(pos,RETRIEVETIME)
end

simple_robots.commands["DEPOSIT ALL BUT SELECTED ELSE GOTO"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	local sl={}
	for p=1,16 do
		if p~=meta:get_int("robot_slot") then
			table.insert(sl,p)
		end
	end
	return vm_deposit(pos,sl)
end

simple_robots.commands["DEPOSIT SELECTED ELSE GOTO"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	return vm_deposit(pos,{meta:get_int("robot_slot")})
end

--"TAKE INTO SELECTED ELSE GOTO" "TAKE ALL AVOID SELECTED ELSE GOTO"

simple_robots.commands["TAKE INTO SELECTED ELSE GOTO"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	return vm_retrieve(pos,{meta:get_int("robot_slot")},true)
end

simple_robots.commands["TAKE ALL AVOID SELECTED ELSE GOTO"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	local sl={}
	for p=1,16 do
		if p~=meta:get_int("robot_slot") then
			table.insert(sl,p)
		end
	end
	return vm_retrieve(pos,sl,false)
end

simple_robots.commands["SWAP SELECTED WITH SLOT"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	local p=tonumber(arg)
	if p==nil then simple_robots.shutdownat(pos) return nil end
	if p<1 then simple_robots.shutdownat(pos) return nil end
	if p>16 then simple_robots.shutdownat(pos) return nil end
	local inv=meta:get_inventory()
	local is=inv:get_stack("main",meta:get_int("robot_slot"))
	local is2=inv:get_stack("main",p)
	inv:set_stack("main",p,is)
	inv:set_stack("main",meta:get_int("robot_slot"),is2)
	return simple_robots.vm_advance(pos,0)
end

simple_robots.commands["IF SELECTED EMPTY THEN GOTO"]=function (pos,arg)
	local meta=minetest.get_meta(pos)
	local is=meta:get_inventory():get_stack("main",meta:get_int("robot_slot"))
	if is:is_empty() then
		return simple_robots.vm_lookup(pos,arg,0)
	end
	return simple_robots.vm_advance(pos,0)
end

--PAGE DEFINITION

simple_robots.commandpages["inventory"]={"SELECT SLOT","DEPOSIT SELECTED ELSE GOTO","DEPOSIT ALL BUT SELECTED ELSE GOTO","TAKE INTO SELECTED ELSE GOTO","TAKE ALL AVOID SELECTED ELSE GOTO","SWAP SELECTED WITH SLOT","IF SELECTED EMPTY THEN GOTO"}
