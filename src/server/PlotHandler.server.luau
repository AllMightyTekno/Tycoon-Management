--[[
   BUGS
   -Scripts don't runfor items when I rejoin after my data saved [DONE]
]]

--[[ TODO
Make Clone looks clean
-Optimization [Later]
]]


local Plots = game.Workspace.Plots
local TemplatePlot = game.Workspace.TemplatePlot


local function GetPlot(plr)
    for _, plot in game.Workspace.Plots:GetChildren() do
        if plot:FindFirstChild("Owner") and plot:GetAttribute("Owner") == plr.UserId then
            return plot
        end
    end
end

local function GetItemFromTemplatePlot(itemId)
    for _, item in TemplatePlot.Items:GetChildren() do
        if item:GetAttribute("Id") ~= itemId then continue end
        return item
    end
end

local function LoadItems(plr: Player, ItemIdTable)
    local PlrPlot = GetPlot(plr)
    
    for _, itemId in ItemIdTable do
      for _, item in TemplatePlot.Items:GetChildren() do
            if item:GetAttribute("Id") ~= itemId then continue end
            
        local item = GetItemFromTemplatePlot(itemId)
        if not item then continue end
            
        local itemClone = item:Clone()
        local RelativeItemCFrame =  TemplatePlot.CFrame:ToObjectSpace(item:GetPivot()) 

            itemClone:PivotTo(PlrPlot.CFrame:ToWorldSpace(RelativeItemCFrame))
            
            -->>Controls the running of scripts inside the itemclone
            for _, scriptObject in Plots:GetDescendants() do
                if scriptObject:IsA("Script") or scriptObject:IsA("LocalScript") then
                    if scriptObject.Enabled ~= false then return end
                    
                        scriptObject.Enabled = true
                end
            end
            
            itemClone.Parent = PlrPlot.Items 
     end
    end
    print("LOADED ALL SAVED ITEMS")
end

local function GetButtonOfIdOfButtonToUnlock(plr:Players, BUTTON_ID)
    local plot = GetPlot(plr)
    if not plot then return end
    
    for _, buttons in plot.Buttons:GetChildren() do
        local IdOfButtonsToUnlock = buttons:GetAttribute("ButtonsToAppear")
        if not IdOfButtonsToUnlock then warn("CANT GET IDS OF BUTTONS TO APPEAR NEXT") continue end

        if BUTTON_ID == IdOfButtonsToUnlock then return buttons end --Returns the button that has the same values as in the 
    end
end

--:Listens for the CreatePlot Event to fire so that it can CreatePlots,AddItems
game.ReplicatedStorage:WaitForChild("CreatePlot").Event:Connect(function(plr, ItemsIdTable)

    print("FIRING CREATING PLOT ")
    --->> Get every plot in the game
    for _, plrplot in Plots:GetChildren() do
        if plrplot:GetAttribute("Taken") then continue end
        
        plrplot:SetAttribute("Taken", true)
        plrplot:SetAttribute('Owner', plr.UserId)
        print("ASSIGNED PLOT TO "..plr.Name)

        local ItemsFolder = Instance.new("Folder", plrplot)
        ItemsFolder.Name = 'Items'

        --Load button and items
        local TemplateButtons = TemplatePlot.Buttons:Clone()
        local TemplateItems = TemplatePlot.Items:Clone()
        
        LoadItems(plr, ItemsIdTable)

        --Setting Items relative to plrplot position on axis
        for _, button: Part in TemplateButtons:GetChildren() do
            if table.find(ItemsIdTable, button:GetAttribute("Id")) then continue end --Won't load the button if the Id Of that item is in the already owned ItemsIdTable
            
            local RelativeButtonCFrame =  TemplatePlot.CFrame:ToObjectSpace(button.CFrame) --If it's model it's button.GetPivot()
            button.CFrame = plrplot.CFrame:ToWorldSpace(RelativeButtonCFrame) 
            
            -->>Set Ui of the button to it's Cash Value
            button.BillboardGui.TextLabel.Text =button.Name.." "..button:GetAttribute("Price").." $"
            
            
            -->>Making buttons appear 2 at once or so
            local LIST_OF_BUTTONS_TO_UNLOCK = button:GetAttribute("ButtonsToAppear")

            if LIST_OF_BUTTONS_TO_UNLOCK then
                local BUTTON_IDS_LIST = string.split(LIST_OF_BUTTONS_TO_UNLOCK, ",") --This will get the string attribute of all the items to unlock from the BUTTONS_TO_APPEAR

                for _, ID in BUTTON_IDS_LIST do --->Getting the individual itemId number
                    local Button:Part = GetButtonOfIdOfButtonToUnlock(plr,ID)
                    
                    if not Button then warn("NO BUTTON" ) continue end
                    if not Button:GetAttribute("Hidden") then continue end --If the button is not hidden then we don't need to do anything
                    
                        --Make button(s) Visible
                    Button.Transparency = 0
                    Button.CanCollide = true
                end



            end
            
            
            -->>Detect when a button is touched to spaw it's item
            button.Touched:Connect(function(hit)
                local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
                local Price = button:GetAttribute("Price")

                if not plr then return end

                if plrplot:GetAttribute("Owner") ~= plr.UserId then return end

                if button:GetAttribute("Debounce") then return end
                
                if not button:GetAttribute("Hidden") then return end

                -->>Prevents buy button from setting multiple items
                button:SetAttribute("Debounce", true)
                task.delay(2, function()
                    if button then
                        button:SetAttribute("Debounce", false)
                    end
                end) 
    
                --TODO REMOVE CURRENCY / CHECK ENOUGH
                local itemToUnlockId = button:GetAttribute("Id")
                if not itemToUnlockId  then warn("No Item to unlock") end

                if Price then
                    if plr.leaderstats.Cash.Value < Price then
                        warn("Not enough cash")
                        return
                    end
                    --If we get to this point player can afford item
                    plr.leaderstats.Cash.Value -= Price
                end
                
                -->>Sets items after player finished the purchase
                for _, item:Model in TemplateItems:GetChildren() do 
                    if button:GetAttribute("Id") ~= item:GetAttribute("Id") then continue end

                    -->>We found correct item to unlock 
                    local RelativeItemCFrame =  TemplatePlot.CFrame:ToObjectSpace(item:GetPivot()) 

                    item:PivotTo(plrplot.CFrame:ToWorldSpace(RelativeItemCFrame))

                    -->>For every item that in the ItemFolder that has scripts it runs as soon as the player buys the item
                    for _, scriptObject:BaseScript in item:GetDescendants() do
                        if scriptObject:IsA("BaseScript") then scriptObject.Enabled = true end
                    end

                    item.Parent = ItemsFolder
                    button:Destroy()
                    game.ServerScriptService.Data.ItemUnlocked:Fire(plr, itemToUnlockId) --Fires when the item is unlocked
                end
            end)

            button.Parent = TemplateButtons

        end

        TemplateButtons.Parent = plrplot

        break
    end
end)



game.Players.PlayerRemoving:Connect(function(plr: Player)
    for _, plot in Plots:GetChildren() do
        if not plot:GetAttribute("Owner") then continue end
        if plot:GetAttribute("Owner") ~= plr.UserId then continue end

        plot:SetAttribute("Taken", nil)
        plot:SetAttribute("Owner", nil)
    end
end)