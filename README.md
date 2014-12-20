simple_robots:Simple programmable robots

#ABOUT
This is a mod that provides simple,programmable,robots.  
They have a (hopefully) extremely simple programming language.  
You have 64 spaces of "command memory" on the robot,each space containing 1 command.  
Most importantly,robots cannot pass through anything except pure air.  
If the air actually is a node(such as water),the robot will not pass though.
If you detect water(you mine a block sucessfully yet you cannot move),place and then mine a block that is very quick to mine.
Failing that,it's either not water,or you have to try again.

#GUIDE
How to use Simple Robots:  
Step 1.Obtain a Simple Robot,either by crafting or creative mode.  
If you want to cheat one in,use "simple_robots:robot_simple_off".  
Here's the recipe:  
* s:Steel Ingot  
* t:Stick  
* m:Mese Crystal  
* g:Glass

The recipe for a simple robot is:

sss  
gmt  
sss

Step 2.Right click on a Simple Robot that is off to modify it's program,or turn it on.

All commands have 1 field,but it may be unused.  
Commands are divided into pages. Different robots have different pages.  
At the moment,I haven't implemented tiers. Yet.

Step 3a.To edit a program,first,select the line you wish to edit from the left panel.  
Step 3b.Then select the page of commands containing the command you want from the bottom.  
        For a full list,see COMMANDS below.  
Step 3c.Find the command.This should be simple enough-the name for a given command is above that command's parameter.  
Step 3d.Now write the parameter,if needed,and press "Set" right of that command's parameter.  
Step 3e.Repeat Step 3's parts until you are done writing or modifying the program.

A example would be:  
SELECT SLOT 1  
FORWARD ELSE GOTO 4  
GOTO 2  
MINE ELSE GOTO 2  
GOTO 2  
This will mine with the tool in slot 1.  
Note that as of the update in which you receive this version of the file,  
the default slot is 1,this is set when you Reset the robot,  
and thus SELECT SLOT 1 can be safely replaced with NOP.  
(Removing it would mean you would have to decrement the line numbers.)

Step 4.Press Reset(goto 1) to start the robot.This will also reset the current slot to 1.  
Step 5.To pause a robot's operation,right click on it. Right click on it again and press "Resume" to continue.  
Step 6.To query where in the program a robot is,pause it,and look at the list on the left.  
       The current line is displayed with a >.  
NOTE:Robots cannot perform computation directly.  
     However,you can write programs that perform operations based upon the presence of blocks.  
     Thus,it may be possible to create a program and a pattern that act as a Turing-Complete language.  
     For the case of "I want to be able to extend my farm",  
     use a block to stop the robot going further than the edge of your farm,  
     then program the robot to return if blocked  
     (by turning twice,going forward until it hits something,then turning back)  
     You will need another block at the start to show the robot where the start is.


#COMMANDS  
##SCOUT
NOP
> Do nothing.

GOTO
> Goes to a line.
> If the argument(aka parameter) is not present or is invalid,shuts down the robot.

FORWARD ELSE GOTO
> Goes forward 1 block.
> If this fails,then goes to a line number if the argument field is present.  
> (If the argument is not present or is invalid,then failing shuts down the robot.)

TURN LEFT
> Turns left.

TURN RIGHT
> Turns right.

UPWARD ELSE GOTO
> Goes up 1 block.
> If this fails,then goes to a line number.
> (no argument=shutdown)

DOWNWARD ELSE GOTO
> Goes down 1 block.
> If this fails,then goes to a line number.
> (no argument=shutdown)

##MINER
MINE ELSE GOTO
> Mines in front of the robot,using a item from the internal inventory.  
> If this fails,then goes to a line number.(no argument=shutdown)  
> Mining will place blocks and items into the robot's inventory.  
> Failing that,the robot will drop them.

MINE UP ELSE GOTO
> Mines above the robot,using a item from the internal inventory.  
> If this fails,then goes to a line number.  
> See MINE ELSE GOTO for where the drops go.  
> (no argument=shutdown)

MINE DOWN ELSE GOTO
> Mines below the robot,using a item from the internal inventory.  
> If this fails,then goes to a line number.  
> See MINE ELSE GOTO for where the drops go.  
> (no argument=shutdown)

PUNCH ELSE GOTO
> Punches in front of the robot,using a item from the internal inventory.  
> Note that due to the unusual way using a tool works,this also doubles as a "use tool".  
> You can use this for lighting TNT if a torch is selected,
> using a hoe of farmland if a hoe is selected,
> rolling paint with paint_roller, and various other things.
> The only failure condition is if there's no node AND there's no tool.  
> If this fails,then goes to a line number.(no argument=shutdown)

PUNCH UP ELSE GOTO
> Punches above the robot,using a item from the internal inventory.  
> Note that due to the unusual way using a tool works,this also doubles as a "use tool".  
> You can use this for lighting TNT if a torch is selected,
> using a hoe of farmland if a hoe is selected,
> rolling paint with paint_roller, and various other things.
> The only failure condition is if there's no node AND there's no tool.  
> If this fails,then goes to a line number.  
> (no argument=shutdown)

PUNCH DOWN ELSE GOTO
> Punches below the robot,using a item from the internal inventory.  
> Note that due to the unusual way using a tool works,this also doubles as a "use tool".  
> You can use this for lighting TNT if a torch is selected,
> using a hoe of farmland if a hoe is selected,
> rolling paint with paint_roller, and various other things.
> The only failure condition is if there's no node AND there's no tool.  
> If this fails,then goes to a line number.  
> (no argument=shutdown)

##BUILDER
PLACE ELSE GOTO
> Places a item ahead of the robot from the internal inventory,  
> in the selected slot.  
> If the item couldn't be placed,then goto a line number.  
> Failing that,shutdown.

PLACE UP ELSE GOTO
> Places a item above the robot from the internal inventory,  
> in the selected slot.  
> If the item couldn't be placed,then goto a line number.  
> Failing that,shutdown.

PLACE DOWN ELSE GOTO
> Places a item below the robot from the internal inventory,  
> in the selected slot.  
> If the item couldn't be placed,then goto a line number.  
> Failing that,shutdown.

##INVENTORY
SELECT SLOT
> Selects a slot.If the number given is invalid,shuts down.

DEPOSIT ALL BUT SELECTED ELSE GOTO
> Moves most items from the 16-slot "internal" storage to a external storage in front of the robot,  
> except for the selected slot.
> If not everything was transferred(for any reason,including there being no storage),  
> then goto a line number. (no argument=shutdown)

#AUTHORS
Expand this if you contribute!
Authors are:
> gamemanj on GitHub,for original mod.
> HybridDog on GitHub,for adding place/dig sounds.

#FAQ  
I can't program the robots!  
> Maybe ask someone who can program them for help?
> Find the Minetest Forums thread this mod is in for more.

I know Lua,and I want to expand this.  
> And you can do so(the license allows it).

The way you wrote the VM is weird.  
> I have to account for metadata that may not even be addressable by the same index after the operation.
> Course the code's going to be weird.
> I pass positions sometimes,metadata on others,depends on if movement is involved.

Why does creative mode mess with robots/How do I protect my server from robots/How do robots do all of this?  
> Essentially,all robots run as their owner by creating a entity,then using metatables to disguise it.  
> This includes area protection.  
> Robots can cause protection violations by any physical action apart from movement.  
> If a robot attempts to move into a protected zone,it will simply fail to do so,  
> without a protection warning.  
> If a robot attempts to mine into a protected zone,  
> it will cause a protection violation.(The robot will see it as a failure,which here means "undiggable/air")  
> If you are a server owner afraid of robots,  
> simply ensure players can't get them unless they forfeit access to most server land.  
> (as in,whitelist certain places they can build)  
> Robots can only work where the player that owns them can,so limiting the player limits the robots.
> This is by design-the robots are always under the player's orders.

Can someone take over my robot and blame it on me?  
> Not unless they can change the program data,which requires admin abilities.(no,you can't use a fake formspec)

Using certain items with PLACE and MINE doesn't work/crashes the server.
> No surprise there.Since the owner could be offline,a "fake player" is used.
> However,it's highly unlikely a crash could happen,as all player functions have no-operation functions by default.
> (See the dev documents on what get_player_name,etc return when used on a entity.
> However,some of these are overriden for hopefully obvious reasons.)
> If a crash does happen,then try using the item in the exact same manner a robot would.
> Should that replicate the crash,it's the item's fault,else,send details to the maintainer of this branch.

What inspired this?  
> Indirectly,the OpenComputers Navigation library being abandoned due to the Microsoft buyup of Mojang,in favour of Minetest.
> I noticed a lack of turtles and computers on Minetest.
> Turtles are more important,as they can be used for automation purposes
> that "factory" and "pipe" mods cannot.

#LICENSE  
This program,it's data,and any other files within this directory or it's subdirectories are licensed under this:

>   DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE  
>  Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified  
 copies of this license document, and changing it is allowed as long  
 as the name is changed.

>   DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE  
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.
