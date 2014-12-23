#MOD API DOCUMENT
#DESCRIPTION
This is the modding API of simple_robots.
It allows you to add your own robot types,add commands,add command pages,
and finally,modify existing command pages and robot types.

#ADDING ROBOT TYPES
If you want a restricted/enhanced version of a robot, you're going to need to make a robot type.
To make a robot type,use:

    simple_robots.register_robot_type(nodeid,description,nodebox,texon,texoff,pageset)

nodeid is the node ID you want the active robot to have.
Since this will be executing from your mod's init.lua, you'll have to use your mod's name.

Description is the description the robot should have.

Nodebox is the nodebox the robot should use when turned off. If nil is passed, the nodebox a ordinary simple_robot uses will be used.

texon and texoff map to the "tiles" field of a nodedef,for when the robot is on and off respectively.

pageset is a table containing the pages this robot should have available.
You can modify this directly afterward,as seen below,but this is here so you can define everything by one call.

Custom behavior outside of command set changes will require node overrides.

#MODIFYING THE SET OF PAGES FOR A TYPE
In order to modify a robot type, you have to know the "off" version of that robot.
This is typically done by getting the "on" version, then adding "\_off" to the end.
The pageset for that robot type is in:`simple_robots.pagesets[on_nodeid.."_off"]`
Modifying this table allows you to add and remove pages.

#ADDING PAGES
In order to add command pages, simply run something like this:

    simple_robots.commandpages["fizzbuzzops"]={"FIZZBUZZ","FIZZ","BUZZ"}

To modify a page,simply modify the page's table.

#ADDING METADATA
In order to add metadata fields, add the name of your field to simple_robots.custommetas:

    simple_robots.custommetas["testmod:metafield"]="defaultvalue"

_Please use the format "modname:fieldname"._

The type of meta created can be either string or int.
Which one is chosen depends on the default value's type.
All other types, including float, are not supported.
If you wish to store a floating point value, convert to a string.

All custommetas will be placed in a "custommetas" table in a tableized robot.
(This in itself can be quite useful, as movement commands rely on the robot_to_table and table_to_robot functions.)
Access your metas the same way you normally would.

(The naming scheme is mostly for compatibility, but it's also because the core minetest engine devs established long ago that they can add reserved metadata.)

#ADDING COMMANDS
This is probably the most important part of the modding API, as without commands, all you can do is make restricted versions of robots.
To add a command,simply write something like:

    simple_robots.commands["PRINT"]=function(pos,arg)
        print(arg)
        return simple_robots.vm_advance(pos,0)
    end

This is a simple command, which prints it's argument to the server console.
GOTO is rather simple,as well:

    simple_robots.commands["GOTO"]=function(pos,arg)
        return simple_robots.vm_lookup(pos,arg,0)
    end

It should be visible by now that by using vm\_lookup, you perform a GOTO,while using vm\_advance, you advance normally.

The 2nd argument of vm\_advance, and the 3rd of vm\_lookup, is the time to return if advancing was successful.
If the line number is invalid, then instead the robot will shutdown.

To perform any useful operation, you need to use the pos argument.
Now to introduce the VM execution loop.

#VM LOOP
The VM execution loop is rather simple.
Count from 1 to 10.
On every iteration, perform vm_run, which runs one command,and returns what it returns.
If vm\_run returns nil, then return false, so the node timer is not modified.
If vm\_run returns something other than 0(apart from the previous), then set the timer to that, and return false.
Else,continue through the counting loop.
If all 10 cycles have been used, then set the timer to CPUTIME, and return false.
This is important, because this affects how timing works.
Furthermore, the nil return allows things like robot shutdown, or the robot moving, without affecting the node timer that's left.

#FUNCTION LIST
This is a plain function list.
After simple\_robots was modularized, many internal functions became part of the API, as they were useful to modders.

    simple_robots.vm_fakeplayer(name,pos,fp_control)
This function creates a fake player.
name is the player name.
pos must be the position of a robot. The robot's selected slot is considered the wielded item.
fp_control is the player's controls. Usually, it is ignored.

    simple_robots.vm_get_wielded(pos)
Gets the wielded item of a robot at pos.

    simple_robots.vm_set_wielded(pos,is)
Sets the wielded item of a robot at pos to is.

    simple_robots.meta_to_program(meta)
Takes the program out of a robot's metadata, and returns it as a table.

    simple_robots.program_to_meta(meta,ser)
Takes a table containing a program, and places it in a robot's metadata.
Command sets are not checked.

    simple_robots.robot_to_table(pos)
Converts a robot to a table.
Only the programming interface variables aren't saved.

    simple_robots.table_to_robot(pos,ser)
Converts a table to a robot.
Note that the node at pos needs to be a robot, or results are undefined.

    simple_robots.shutdownat(pos)
This shuts down the robot at pos.
This includes adding "_off" to the node name.
Do not shutdown a robot that is already off.
Although it is not fatal, please return nil in any command that does this.
This is handled automatically by the advance and lookup functions in case of invalid IP.

    simple_robots.vm_is_air(nt)
Very simple function. Takes the result of minetest.get_node(pos).
This is because I honestly find all the different names for air confusing.

    simple_robots.vm_can_add(owner,pos)
If the only node at pos is air, and owner has permissions there, return true.
Note that you should use minetest functions like on_place where possible.

    simple_robots.vm_advance(pos,rtime)
Advances the IP stored in pos.
If the IP fell off the end of the list, it returns nil-else it returns rtime.
Generally meant to be used like this: `return simple_robots.vm_advance(pos,MAGICTIME)`

    simple_robots.vm_lookup(pos,arg,rtime)
Sets the IP to a line number.
The command's argument should be provided in arg.
If the line number is invalid,then shuts down the robot and returns nil.
Generally meant to be used like this: `return simple_robots.vm_lookup(pos,arg,MAGICTIME)`
However, it can be used in other ways.
It's just easier to read this way, as it quickly specifies how the function ends.

    simple_robots.resetmeta(meta)
Resets the metadata of a robot.
This is hardly ever useful outside of on_construct functions,
but if someone finds a use for it, it's here, and will always set all the metadata.
Since this is called by on_construct functions for safety purposes, it's usually useless.
(It will not clear inventory slots, but it does set_size.)

    simple_robots.register_robot_type(nodeid,description,nodebox,tex_on,tex_off,pageset)
This will register 2 nodes.
One is the robot while active(`nodeid`), and the other is the robot while not active(`nodeid.."_off"`).
`description` is the description for both.
`nodebox` is the nodebox while off.
`tex_on` is the texture set while on, and `tex_off` is the texture set while off.
Finally, `pageset` is the list of command pages this robot type has available to it.
Custom behavior outside of command set changes will require node overrides.

#POSSIBLE FUTURE FEATURES

##CALLBACK SYSTEM
In future, a callback system may be added allowing stuff like energy consumption.

The callbacks would be called if the node timer was set by the VM loop.
If the robot is missing, then the command that did so is not using the nil return correctly.
Hence, a callback will probably be added by default which causes an error, so that the programmer of said command will fix it before it causes issues with callback mods.

##SWITCH "TURN OFF" TO PUNCH
This would allow using on_rightclick for custom controls for that specific robot type.
Implementation of that will be done by writing to formspec, and performing nodedef overrides.
Do not put formspec in custommetas, it'll be overwritten anyway.

This potentially allows for _standalone programmable computers_ using the same system as the robots.
