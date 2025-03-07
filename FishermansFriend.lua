-- FishermansFriend.lua
FishermansFriend = {
    caughtFish = {},
    level = 1,
    xp = 0,
    sortOrder = "name"
}

local RARE_FISH = {
    ["|H1:item:43562:...|h[Cyrodiil Eel]|h"] = true,
    ["|H1:item:43565:...|h[Old Salty's Worm]|h"] = true
}

local XP_PER_FISH = 10
local XP_PER_RARE_FISH = 50
local XP_PER_LEVEL = 100

local function UpdateLevel()
    while FishermansFriend.xp >= XP_PER_LEVEL do
        FishermansFriend.xp = FishermansFriend.xp - XP_PER_LEVEL
        FishermansFriend.level = FishermansFriend.level + 1
        d("FishermansFriend: Level up! Now level " .. FishermansFriend.level)
    end
end

local function OnLootReceived(eventCode, lootedBy, itemLink, quantity, itemSound, lootType, isStolen)
    if lootType == LOOT_TYPE_ITEM then
        local fishName = GetItemLinkName(itemLink)
        if not FishermansFriend.caughtFish[fishName] then
            FishermansFriend.caughtFish[fishName] = { count = 0, icon = GetItemLinkIcon(itemLink), rare = RARE_FISH[itemLink] }
        end
        FishermansFriend.caughtFish[fishName].count = FishermansFriend.caughtFish[fishName].count + quantity
        
        local xpGain = RARE_FISH[itemLink] and XP_PER_RARE_FISH or XP_PER_FISH
        FishermansFriend.xp = FishermansFriend.xp + xpGain
        d("Caught: " .. fishName .. " (XP: " .. xpGain .. ")")
        
        UpdateLevel()
    end
end

local function CreateUI()
    if FishermansFriendWindow then FishermansFriendWindow:SetHidden(false) return end
    
    local window = WINDOW_MANAGER:CreateTopLevelWindow("FishermansFriendWindow")
    window:SetDimensions(500, 500)
    window:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    window:SetMovable(true)
    window:SetMouseEnabled(true)
    window:SetClampedToScreen(true)
    
    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendBG", window, "ZO_DefaultBackdrop")
    backdrop:SetAnchorFill()
    
    local title = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendTitle", window, "ZO_WindowTitle")
    title:SetAnchor(TOP, window, TOP, 0, 10)
    title:SetText("Fishing Bestiary")
    
    local closeButton = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendClose", window, "ZO_CloseButton")
    closeButton:SetAnchor(TOPRIGHT, window, TOPRIGHT, -5, 5)
    closeButton:SetHandler("OnClicked", function() window:SetHidden(true) end)
    
    local levelLabel = WINDOW_MANAGER:CreateControl("FishermansFriendLevel", window, CT_LABEL)
    levelLabel:SetFont("ZoFontGame")
    levelLabel:SetText("Level: " .. FishermansFriend.level .. " (XP: " .. FishermansFriend.xp .. "/" .. XP_PER_LEVEL .. ")")
    levelLabel:SetAnchor(TOP, title, BOTTOM, 0, 10)
    
    local xpBar = WINDOW_MANAGER:CreateControl("FishermansFriendXPBar", window, CT_STATUSBAR)
    xpBar:SetDimensions(300, 20)
    xpBar:SetAnchor(TOP, levelLabel, BOTTOM, 0, 10)
    xpBar:SetMinMax(0, XP_PER_LEVEL)
    xpBar:SetValue(FishermansFriend.xp)
    xpBar:SetTexture("EsoUI/Art/Miscellaneous/progressBar_fill.dds")
    
    local scrollContainer = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendScroll", window, "ZO_ScrollContainer")
    scrollContainer:SetDimensions(460, 300)
    scrollContainer:SetAnchor(TOP, xpBar, BOTTOM, 0, 20)
    
    function UpdateUI()
        
        local fishList = {}
        for fishName, data in pairs(FishermansFriend.caughtFish) do
            table.insert(fishList, { name = fishName, count = data.count, icon = data.icon, rare = data.rare })
        end
        
        if FishermansFriend.sortOrder == "count" then
            table.sort(fishList, function(a, b) return a.count > b.count end)
        else
            table.sort(fishList, function(a, b) return a.name < b.name end)
        end
        
        local yOffset = 0
        for _, fish in ipairs(fishList) do
            local tile = WINDOW_MANAGER:CreateControl(nil, scrollContainer:GetNamedChild("scrollChild"), CT_CONTROL)
            tile:SetDimensions(100, 100)
            tile:SetAnchor(TOPLEFT, scrollContainer:GetNamedChild("scrollChild"), TOPLEFT, 0, yOffset)
            
            local icon = WINDOW_MANAGER:CreateControl(nil, tile, CT_TEXTURE)
            icon:SetDimensions(64, 64)
            icon:SetAnchor(TOP, tile, TOP, 0, 0)
            icon:SetTexture(fish.icon)
            
            local label = WINDOW_MANAGER:CreateControl(nil, tile, CT_LABEL)
            label:SetFont("ZoFontGame")
            label:SetText(fish.name .. " x" .. fish.count)
            label:SetAnchor(TOP, icon, BOTTOM, 0, 5)
            
            yOffset = yOffset + 110
        end
        
        levelLabel:SetText("Level: " .. FishermansFriend.level .. " (XP: " .. FishermansFriend.xp .. "/" .. XP_PER_LEVEL .. ")")
        xpBar:SetValue(FishermansFriend.xp)
    end
    
    UpdateUI()
end

SLASH_COMMANDS["/ff"] = function()
    CreateUI()
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= "FishermansFriend" then return end
    FishermansFriend = ZO_SavedVars:New("FishermansFriendData", 1, nil, {
        caughtFish = {},
        level = 1,
        xp = 0,
        sortOrder = "name"
    })

    EVENT_MANAGER:RegisterForEvent("FishermansFriend", EVENT_LOOT_RECEIVED, OnLootReceived)
end

EVENT_MANAGER:RegisterForEvent("FishermansFriend", EVENT_ADD_ON_LOADED, OnAddonLoaded)
