--EDITING NOTES:
--USE NOTEPAD++ OR PROGRAMMER'S NOTEPAD-THESE EDITORS HAVE TAB CONTROL!
--TURN OFF TABS! THEY ARE A INCONSISTENT MESS AND I DON'T KNOW WHY THEY ARE STILL DEFAULT!
--IF YOU'VE BEEN EDITING AND HAVE IGNORED THIS NOTE,THEN USE:
--NOTEPAD++:EDIT/BLANK OPERATIONS/TAB TO SPACE!
--PROGRAMMER'S NOTEPAD:EDIT/CONVERT TABS TO SPACES

--This contains the mod name.
--It's not auto-detected,as if somebody uses a incorrect name,then renames it...
local MOD_NAME="simple_robots"

--TODO:Make it so that command sets are indexed in a sane way.
--     At the moment,as all functions have some way of
--     getting the "robot which is turned on" block ID for this tier,that's used.
--TIMING RULES FOR ROBOTS
--Essentially,if a command is "structural" (nop,goto,forward if the robot is blocked,up under said conditions,down-ditto)
--Then the command will add 1 to a counter(starting at 0) and simply continue in the same tick.
--If the counter ever reaches 10,then the robot will pause until next tick.
--If a command is "animated"(forward if success,turn left,turn right,up if success,down if success,beep,1sec),
--then the VM will stop earlier in the tick,wait a second,and then start again with the counter reset.
--Hence,as long as you don't have more than 10 structural commands in a given run,your robot will never
--freeze for a second due to VM load.
--If you're wondering why the VM is so slow,it's to add a nice element of optimization.

--NOTE:DO NOT CHANGE!
local CODELINES=64

--USELESS ENTITY(Basically abusing the 'player methods return safe values' behavior)
--This entity needs to be explicitly cleaned up so that if a really bad error occurs during a MINE/PLACE,
--the player has notification of "which robot broke everything"

minetest.register_entity(MOD_NAME..":fakeplayer",
{
physical = false,
})

--PROGRAMMER INTERFACE
local command_sets={}
--Command sets can have up to 7 commands in them.
command_sets["scout"]={"NOP","GOTO","FORWARD ELSE GOTO","TURN LEFT","TURN RIGHT","UPWARD ELSE GOTO","DOWNWARD ELSE GOTO"}
command_sets["miner"]={"MINE ELSE GOTO","MINE UP ELSE GOTO","MINE DOWN ELSE GOTO","PUNCH ELSE GOTO","PUNCH UP ELSE GOTO","PUNCH DOWN ELSE GOTO"}
command_sets["builder"]={"PLACE ELSE GOTO","PLACE UP ELSE GOTO","PLACE DOWN ELSE GOTO"}
command_sets["inventory"]={"SELECT SLOT","DEPOSIT ALL BUT SELECTED ELSE GOTO"}
--Command set sets are how the user chooses between the wide assortment of commands available in a simple manner.
--(Read:It allows choosing which set you use.)
local command_set_sets={}
command_set_sets[MOD_NAME..":robot_simple"]={"scout","miner","builder","inventory"}
local function genProgrammer(ct,meta)
    local set=command_sets[meta:get_string("command_page")]
    local pages=command_set_sets[ct]
    local wid=(8/1.25)+2
    local res="size[17,"..wid.."]"
    local pc=meta:get_int("robot_pc")
    res=res.."textlist[0,0;3,"..wid..";lines;"
    for l=1,CODELINES do
        if l~=1 then res=res.."," end
        if l==pc then
            res=res.."> "
        else
            res=res.."_ "
        end
        res=res..meta:get_string("program_"..l.."_op").." "..meta:get_string("program_"..l.."_msg")
    end
    res=res.."]"
    local pos=3.25
    --Note:Due to the bigger fields of 0.4.10,I've had to shuffle the layout a bit.
    for p,v in ipairs(pages) do
        res=res.."button["..pos..","..(wid-0.5)..";1.75,1;cmdpage"..p..";"..v.."]"
        pos=pos+1.50
    end
    --For some reason LN liked to equal 0.
    --Doesn't happen anymore,but may as well leave a perfectly good check.
    local ln=meta:get_int("lineno")
    if (ln~=nil) and (ln~=0) then
        res=res.."label[3.25,0;Line "..ln.."="..(meta:get_string("program_"..ln.."_op").." "..meta:get_string("program_"..ln.."_msg")).."]"
        for p,v in ipairs(set) do
            --This deliberately acts against the auto-spacing to conserve space
            --for more commands.
            res=res.."button[7.25,"..(p+0.2)..";1,1;cmd"..p..";Set]"
            res=res.."field[3.25,"..(p+0.2)..";4,1;msg"..p..";"..v..";]"
        end
    end
    res=res.."label[8.25,-0.25;Player Inventory]"
    res=res.."label[8.25,4.2;Robot Inventory]"
    res=res.."list[current_player;main;8.25,0.25;8,4;]"
    res=res.."list[context;main;8.25,4.7;8,2;]"

    --Reset resets the robot,resume simply resumes it.
    res=res.."button[8.25,"..(wid-1.75)..";1.75,1;reset;Reset(goto 1)]"
    res=res.."button[9.75,"..(wid-1.75)..";1.25,1;resume;Resume]"
    return res
end

--VM

--Fake player code.
--This doesn't have to be perfect,
--it just has to handle EXPECTED behaviors.
--Causing weird errors when a buggy item comes along is fine,
--since that item should be tested by the author anyway(to state it another way:not my fault)
local function vm_fakeplayer(name,pos,fp_control,selectedslot)
    local fake_player=minetest.add_entity(pos,MOD_NAME..":fakeplayer")
    local actual={}
    local actual_meta={}
    actual_meta.__index=function(tab,ind)
        print("UNIMPLEMENTED ROBOT FUNCTION:"..ind)
        local i=fake_player[ind]
        return function(...) local a={...} a[1]=fake_player return i(unpack(a)) end
    end
    actual.get_player_name=function ()
        return name
    end
    actual.get_inventory=function (_)
        return minetest.get_meta(pos):get_inventory()
    end
    actual.get_wielded_item=function (_)
        return minetest.get_meta(pos):get_inventory():get_stack("main",selectedslot)
    end
    actual.set_wielded_item=function (_,is)
        return minetest.get_meta(pos):get_inventory():set_stack("main",selectedslot,is)
    end
    actual.get_player_control=function (_)
        return fp_control
    end
    actual.is_player=function (_)
        return true
    end
    setmetatable(actual,actual_meta)
    return actual
end

--Load/Save to/from meta
local function vm_serialize_program(meta)
    local ser={}
    for x=1,CODELINES do
        ser[x]={}
        ser[x].op=meta:get_string("program_"..x.."_op")
        ser[x].msg=meta:get_string("program_"..x.."_msg")
    end
    return ser
end
local function vm_deserialize_program(meta,ser)
    for x=1,CODELINES do
        meta:set_string("program_"..x.."_op",ser[x].op)
        meta:set_string("program_"..x.."_msg",ser[x].msg)
    end
end
local function vm_serialize(pos)
    local ser={}
    local meta=minetest.get_meta(pos)
    ser.pc=meta:get_int("robot_pc")
    ser.slot=meta:get_int("robot_slot")
    ser.owner=meta:get_string("robot_owner")
    ser.prog=vm_serialize_program(meta)
    ser.inv=meta:get_inventory():get_list("main")--All's fair in love,war,and minetest modding.
    return ser
end
local function vm_deserialize(pos,ser)
    local meta=minetest.get_meta(pos)
    meta:set_int("robot_pc",ser.pc)
    meta:set_int("robot_slot",ser.slot)
    meta:set_string("robot_owner",ser.owner)
    vm_deserialize_program(meta,ser.prog)
    ser.inv=meta:get_inventory():set_list("main",ser.inv)
end

--Will shutdown the robot.
local function vm_shutdown(pos)
    local ser=vm_serialize(pos)
    local tp=minetest.get_node(pos).name
    minetest.set_node(pos,{name=tp.."_off",param2=minetest.get_node(pos).param2})
    vm_deserialize(pos,ser)
    local meta=minetest.get_meta(pos)
    --NOTE:When the node is created,command_page and such are reset.
    --But the formspec wasn't updated after vm_deserialize.Fix that.
    meta:set_string("formspec",genProgrammer(tp,meta))
end

--Quick function so that once I figure out which of these I can remove,it's automatic :)
local function vm_is_air(nt)
    return nt.name=="" or nt.name=="air"
end
--p_place:Can we place something here(including ourselves)
local function vm_p_place(owner,pos)
    local nt=minetest.get_node(pos)
    if owner=="" then return false end
    local protected=minetest.is_protected(pos, owner)
    return (not protected) and vm_is_air(nt)
end
--p_mine:Can we remove something from here?
local function vm_p_mine(owner,pos)
    local nt=minetest.get_node(pos)
    if owner=="" then return false end
    local protected=minetest.is_protected(pos, owner)
    return (not protected) and (not vm_is_air(nt))
end

local function vm_advance(pos)
    local meta=minetest.get_meta(pos)
    local pc=meta:get_int("robot_pc")
    if pc==CODELINES then meta:set_int("robot_pc",0) vm_shutdown(pos) return false end
    meta:set_int("robot_pc",pc+1)
    return true
end
--This originally supported labels,but I removed them to simplify things.
--There's only 32 lines.
local function vm_lookup(pos,label)
    local x=tonumber(label)
    local meta=minetest.get_meta(pos)
    if x~=nil then
        if (x>0) and (x<=CODELINES) then
            meta:set_int("robot_pc",x)
            return true
        end
    end
    meta:set_int("robot_pc",0)
    vm_shutdown(pos)
    return false
end
--TP COMMAND FUNCTION
--Basically a "movement command" function.(as in,forward,up,down)
--This returns true if the TP was a success,false if it failed.
--This can be inverted for the correct vm_run response.
--If it's false,return vm_lookup instead!!!
--NOTE:No protection check is done for pos1,since that's where the robot is.
local function vm_tp(pos1,dir,arg)
    local pos2=vector.add(pos1,dir)
    local meta=minetest.get_meta(pos1)
    local ser=vm_serialize(pos1)
    if not vm_p_place(ser.owner,pos2) then return vm_lookup(pos1,arg) end
    minetest.set_node(pos2,minetest.get_node(pos1))
    minetest.set_node(pos1,{name="air"})
    
    nodeupdate(pos1)
    nodeupdate(pos2)
    --NOTE:Meta is left invalid since both these calls use pos2.
    vm_deserialize(pos2,ser)
    vm_advance(pos2)
    return false
end
local function vm_mine(pos1,dir,arg)
    local meta=minetest.get_meta(pos1)
    local pos2=vector.add(pos1,dir)
    local node=minetest.get_node(pos2)
    if vm_is_air(node) then return vm_lookup(pos1,arg) end
    local fp=vm_fakeplayer(meta:get_string("robot_owner"),pos1,{sneak=false},meta:get_int("robot_slot"))
    if not fp then return vm_lookup(pos1,arg) end
    minetest.registered_nodes[node.name].on_dig(pos2, node, fp)
    fp:remove()
    --The block not being air is considered "failure".
    if (not vm_is_air(minetest.get_node(pos2))) then return vm_lookup(pos1,arg) end
    vm_advance(pos1)
    return false
end
--NOTE:This handles both the use of a tool and the punch itself.
local function vm_punch(pos1,dir,arg)
    local meta=minetest.get_meta(pos1)
    local pos2=vector.add(pos1,dir)
    local node=minetest.get_node(pos2)
    local fp=vm_fakeplayer(meta:get_string("robot_owner"),pos1,{sneak=false},meta:get_int("robot_slot"))
    local stk=meta:get_inventory():get_stack("main",meta:get_int("robot_slot"))
    if not fp then return vm_lookup(pos1,arg) end
    local success=false
    local pointedthing={type="nothing"}
    if (not vm_is_air(node)) then
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
    if not success then return vm_lookup(pos1,arg) end
    vm_advance(pos1)
    return false
end
local function vm_place(pos1,dir,arg)
    local meta=minetest.get_meta(pos1)
    local pos2=vector.add(pos1,dir)
    if not vm_is_air(minetest.get_node(pos2)) then return vm_lookup(pos1,arg) end
    local owner=meta:get_string("robot_owner")
    local stk=meta:get_inventory():get_stack("main",meta:get_int("robot_slot"))
    if stk:is_empty() then return vm_lookup(pos1,arg) end
    local fp=vm_fakeplayer(owner,pos1,{sneak=true},meta:get_int("robot_slot"))
    if not fp then return vm_lookup(pos1,arg) end
    local res,tf=stk:get_definition().on_place(stk,fp,{type="node",under=pos1,above=pos2})
    fp:remove()
    meta:get_inventory():set_stack("main",meta:get_int("robot_slot"),res)
    if not tf then return vm_lookup(pos1,arg) end
    vm_advance(pos1)
    return false
end
local function vm_turn(pos,dir)
    local ser=vm_serialize(pos)
    minetest.set_node(pos,{name=minetest.get_node(pos).name,param2=((minetest.get_node(pos).param2+dir)%4)})
    vm_deserialize(pos,ser)
    vm_advance(pos)
    return false
end
--Main VM function.
--This returns true if the VM should continue running this tick.
--NOTE:vm_shutdown relies on concatting the node name with "_off".
local function vm_run(pos)
    local meta=minetest.get_meta(pos)
    local pc=meta:get_int("robot_pc")
    if pc==0 then vm_shutdown(pos) return false end
    local command=meta:get_string("program_"..pc.."_op")
    local arg=meta:get_string("program_"..pc.."_msg")
    --print("RAN "..command.." "..arg)--debug,the actual ingame debugger isn't up yet,if there'll ever be one at all
    --NOTE ON ADDING COMMANDS
    --For a script command(NOP,GOTO,IF,similar) use "return vm_advance(pos)" or "return vm_lookup(meta,arg)"
    --For a animated command(TURN LEFT,FORWARD,TURN RIGHT,similar)
    --Use "vm_advance(pos) return false" or "vm_lookup(meta,arg) return false"
    --All animations last 1 second for consistency.
    --I have no intention to change this,the code's a mess as-is due to all the "failure conditions".
    if (command=="NOP") then

        return vm_advance(pos)
    end
    if command=="TURN LEFT" then
        return vm_turn(pos,-1)
    end
    if command=="TURN RIGHT" then
        return vm_turn(pos,1)
    end
    if command=="FORWARD ELSE GOTO" then
        return vm_tp(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
    end
    if command=="UPWARD ELSE GOTO" then
        return vm_tp(pos,{x=0,y=1,z=0},arg)
    end
    if command=="DOWNWARD ELSE GOTO" then
        return vm_tp(pos,{x=0,y=-1,z=0},arg)
    end
    if command=="MINE ELSE GOTO" then
        return vm_mine(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
    end
    if command=="MINE UP ELSE GOTO" then
        return vm_mine(pos,{x=0,y=1,z=0},arg)
    end
    if command=="MINE DOWN ELSE GOTO" then
        return vm_mine(pos,{x=0,y=-1,z=0},arg)
    end
    if command=="PUNCH ELSE GOTO" then
        return vm_punch(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
    end
    if command=="PUNCH UP ELSE GOTO" then
        return vm_punch(pos,{x=0,y=1,z=0},arg)
    end
    if command=="PUNCH DOWN ELSE GOTO" then
        return vm_punch(pos,{x=0,y=-1,z=0},arg)
    end
    if command=="GOTO" then
        return vm_lookup(pos,arg)
    end
    if command=="DEPOSIT ALL BUT SELECTED ELSE GOTO" then
        local pos2=vector.add(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2))
        --Permissions check.
        if not vm_p_mine(meta:get_string("robot_owner"),pos2) then return vm_lookup(pos1,arg) end
    
        --Okay,first:Is there a inventory in front of us with a sub-inventory called "main"?
        --If so,it's either another robot(wow,robot transport!),a chest,or a node breaker :)
        --None are any loss.
        local tgtmeta=minetest.get_meta(pos2)
        local my_inv=meta:get_inventory()
        local inv=tgtmeta:get_inventory()
        local lookup=false
        if inv:get_size("main")<1 then
            lookup=true
        else
            for p=1,16 do
                if p~=meta:get_int("robot_slot") then
                    local is=inv:add_item("main",my_inv:get_stack("main", p))
                    if is~=nil then if is:is_empty() then lookup=true end end
                    my_inv:set_stack("main",p,is)
                end
            end
        end
        if lookup then
            return vm_lookup(pos,arg)
        end
        return vm_advance(pos)
    end
    if command=="SELECT SLOT" then
        local p=tonumber(arg)
        if p==nil then vm_shutdown(pos) return false end
        if p<1 then vm_shutdown(pos) return false end
        if p>16 then vm_shutdown(pos) return false end
        meta:set_int("robot_slot",p)
        return vm_advance(pos)
    end
    if command=="PLACE ELSE GOTO" then
        return vm_place(pos,minetest.facedir_to_dir(minetest.get_node(pos).param2),arg)
    end
    if command=="PLACE UP ELSE GOTO" then
        return vm_place(pos,{x=0,y=1,z=0},arg)
    end
    if command=="PLACE DOWN ELSE GOTO" then
        return vm_place(pos,{x=0,y=-1,z=0},arg)
    end
    --If this EVER happens,something is really wrong with the save file.
    print("Corrupted robot program @ "..(pos.x)..","..(pos.y)..","..(pos.z).." (not the fault of the robot's owner,this is save file corruption) missing command:"..tostring(command))
    vm_shutdown(pos)
    return false
end

--VM RESET FUNCTION
--Used to avoid crashes should a "accident" happen.
local function vm_reset(meta)
    local inv=meta:get_inventory()
    inv:set_size("main", 16)
    meta:set_string("robot_owner", "")
    for p=1,CODELINES do
        meta:set_string("program_"..p.."_op", "NOP")
        meta:set_string("program_"..p.."_msg", "")
    end
    meta:set_int("robot_pc", 1)
end

--ROBOT BLOCK

local function register_robot_type(tp,name)
    local nodebox={
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
    }
    minetest.register_node(MOD_NAME..":robot_"..tp, {
        description = name.." (please don't place,won't set owner)",
        tiles ={MOD_NAME.."_robot_on_top.png",
                MOD_NAME.."_robot_bottom.png",
                MOD_NAME.."_robot_side.png",
                MOD_NAME.."_robot_side.png",
                MOD_NAME.."_robot_back.png",
                MOD_NAME.."_"..tp.."_front.png"},
        --DON'T NODEBOX SOMETHING THAT WILL BE TELEPORTING ITSELF ONCE EVERY SECOND
        --drawtype = "nodebox",
        --node_box = nodebox,
        paramtype = "light",
        paramtype2 = "facedir",
        drop=MOD_NAME..":robot_"..tp.."_off",
        legacy_facedir_simple = true,
        is_ground_content = false,
        groups = {dig_immediate=2,not_in_creative_inventory=1},
        sounds = default.node_sound_defaults(),
        on_construct = function(pos)
            vm_reset(minetest.get_meta(pos))
            local tmr = minetest.get_node_timer(pos)
            tmr:start(1)
        end,
        on_timer = function (pos,elapsed)
            local i=0
            while (vm_run(pos) and (i<10)) do i=i+1 end
            --Either the robot 'crashed' or we're now animating. In this function,the difference is purely academic.
            return true
        end,
        on_rightclick = function (pos, node, clicker, itemstack)
            local meta=minetest.get_meta(pos)
            local own=meta:get_string("robot_owner")
            if (clicker:get_player_name()~=own) and own~="" then
                return 
            end
            vm_shutdown(pos)
        end,
    })
    minetest.register_node(MOD_NAME..":robot_"..tp.."_off", {
        description = name,
        tiles ={MOD_NAME.."_robot_off_top.png",
                MOD_NAME.."_robot_bottom.png",
                MOD_NAME.."_robot_side.png",
                MOD_NAME.."_robot_side.png",
                MOD_NAME.."_robot_back.png",
                MOD_NAME.."_off_front.png"},
        drawtype = "nodebox",
        node_box = nodebox,
        paramtype = "light",
        paramtype2 = "facedir",
        legacy_facedir_simple = true,
        is_ground_content = false,
        groups = {dig_immediate=2},
        sounds = default.node_sound_defaults(),
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            vm_reset(meta)
            meta:set_int("lineno",1)
            meta:set_string("command_page","scout")
            meta:set_string("formspec",genProgrammer(MOD_NAME..":robot_"..tp,meta))
        end,
        after_place_node = function (pos,placer,itemstack,pointed_thing)
            minetest.get_meta(pos):set_string("robot_owner",placer:get_player_name())
        end,
        on_receive_fields = function(pos, formname, fields, sender)
            local meta=minetest.get_meta(pos)
            local own=meta:get_string("robot_owner")
            if (sender:get_player_name()~=own) and own~="" then
                return 
            end
            --CLAIMING OWNERSHIP OF A ROBOT WITH MISSING OWNER-TAG
            --(how can this happen,you may ask? naive worldeditors,that's how!)
            if (own=="") and fields.claim then
                meta:set_string("robot_owner",sender:get_player_name())
            end
            if fields.lines then
                if fields.lines:sub(1,4)=="CHG:" then
                    meta:set_int("lineno",tonumber(fields.lines:sub(5)))
                end
            end
            if fields.reset or fields.resume then
                local ser=vm_serialize(pos)
                if fields.reset then ser.pc=1 end
                minetest.set_node(pos,{name=MOD_NAME..":robot_"..tp,param2=minetest.get_node(pos).param2})
                --Timer is enabled by default (intentional!)
                vm_deserialize(pos,ser)
                return --don't set formspec!!!
            end
            local ct=MOD_NAME..":robot_"..tp
            for k,v in ipairs(command_set_sets[ct]) do
                if fields["cmdpage"..k] then
                    meta:set_string("command_page",v)
                end
                if meta:get_string("command_page")==v then
                    for k2,v2 in ipairs(command_sets[v]) do
                        if fields["cmd"..k2] then
                            local ln=meta:get_int("lineno")
                            if (ln~=nil) and (ln~=0) then
                                meta:set_string("program_"..ln.."_op",v2)
                                meta:set_string("program_"..ln.."_msg",fields["msg"..k2])
                            end
                        end
                    end
                end
            end
            meta:set_string("formspec",genProgrammer(ct,meta))
        end
    })
end
--TIERS.
--The whole reason I wrote register_robot_type is because if people are going to
--make robots with stupid amounts of commands,they should at least make tiers.
--One,so that people introduced won't be overwhelmed.
--Two,so that crafting recipes can be 'gradual'.
--Tiers are:
--simple:Scouting,building,mining.Cannot really perform computation.
--TODO:counting:Simple,with the counters page.(basically brainfuck with a few extra commands)
--TODO:advanced:More advanced counters(remove old counters page,insert expanded)
--TODO:ultimate:Adds a "formspec" page,which should be capable of REPROGRAMMING A ROBOT.
--Also,support for different tiers having different code sizes.
--Ultimate tier should get 192 lines,while advanced gets 128,counting gets 96,simple stays at 64.
--"in case of running off the end of the list" checks will need adjusting.
--Search and replace for CODE_SIZE should be enough!
register_robot_type("simple","Simple Robot")

--Recipes are in another file
loadfile(minetest.get_modpath(minetest.get_current_modname()).."/recipes.lua")(MOD_NAME)