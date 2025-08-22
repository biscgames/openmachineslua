# OPENMACHINES
OpenMachines is an open-source game about working with machernery and extracting resources from deposits
<br/>
# Docs for players:
To select machines, left-click<br/>
To remove machines, middle-click<br/>
To interact with machines, right-click<br/><br/>

There are deposits scattered around, the black and white ones only have bones while the blue ones have iron, gold and etherium<br/>
Use an extractor to extract resources! Put an extractor below the deposit (or above if it's an advanced extractor, advanced extractors can go both above and below)<br/>
Every machine needs an activated switch at the left, add one!<br/>
The extractors always need storage to store items. Add one at their right!<br/>
## Machine-wiki
Switch: The only machine that isnt implemented by a coremod, usually activates the machine at its right. Right-click to turn on and off, they're off by default<br/>
Extractor: The extractor extracts from the deposits that are scattered around the grid. Only extracts deposits from above<br/>
Advanced Extractor: Functions similarly to the Extractor but can also extract deposits from below, meaning if you prayed to rngesus hard enough and have a vertical 1 block gap of 2 deposits you can put it between them for double efficiency<br/>
Simple Storage: Only stores 1 item, right-click to put all items into player inventory<br/>
Storage: Stores 3 items, works the same as Simple Storage though
# Docs for modders:
Sorry if it's rough I'm making this readme file on my phone! Still trying to work on these docs, for now check api.lua, the comments explain the functions more thoroughly<br/>

`api.register_machine(id,definition)`<br/>
This function registers a machine to the registered_machines variable. E.G:
```lua
local done = false
api.register_machine("buttonmod:button",{
    name = "Button",
    type = "switch",
    img_m = "button.png",
    self.switch_on = false
    on_update = function(self,grid,r,c) do
        if not done then done = true
        else
            done = false
            self.switch_on = false
        end
    end
})
```