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
        -- need to account for COLLECTIBLE (34) fish (Green, Blue etc.)
        d("Item is: " .. itemLink .. " and it is a " .. GetItemLinkItemType(itemLink))
        if GetItemLinkItemType(itemLink) == ITEMTYPE_FISH then
            if FishermansFriend.caughtFish[itemLink] then
                FishermansFriend.caughtFish[itemLink] = FishermansFriend.caughtFish[itemLink] + 1
            else
                FishermansFriend.caughtFish[itemLink] = 1
            end

            local xpGain = RARE_FISH[itemLink] and XP_PER_RARE_FISH or XP_PER_FISH
            FishermansFriend.xp = FishermansFriend.xp + xpGain
            d("Caught: " .. itemLink .. " (XP: " .. xpGain .. ")")

            UpdateLevel()
            UpdateUI()
        end
    end
end

local function CreateUI()
    if FishermansFriendWindow then
        FishermansFriendWindow:SetHidden(false)
        return
    end

    local window = WINDOW_MANAGER:CreateTopLevelWindow("FishermansFriendWindow")
    window:SetDimensions(500, 500)
    window:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    window:SetMovable(true)
    window:SetMouseEnabled(true)
    window:SetClampedToScreen(true)

    -- Backdrop
    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendBG", window, "ZO_DefaultBackdrop")
    backdrop:SetAnchorFill()
    -- End Backdrop

    -- Title text
    local title = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendTitle", window, "ZO_WindowTitle")
    title:SetAnchor(TOP, window, TOP, 0, 10)
    title:SetText("Fisherman's Friend")
    -- ENd Title text

    -- Close Button
    local closeButton = WINDOW_MANAGER:CreateControlFromVirtual("FishermansFriendClose", window, "ZO_CloseButton")
    closeButton:SetAnchor(TOPRIGHT, window, TOPRIGHT, -5, 5)
    closeButton:SetHandler("OnClicked", function()
        window:SetHidden(true)
    end)
    -- End Close Button

    -- Level Label
    local levelLabel = WINDOW_MANAGER:CreateControl("FishermansFriendLevel", window, CT_LABEL)
    levelLabel:SetFont("ZoFontGame")
    levelLabel:SetText("Level: " .. FishermansFriend.level .. " (XP: " .. FishermansFriend.xp .. "/" .. XP_PER_LEVEL ..
                           ")")
    levelLabel:SetAnchor(TOP, title, BOTTOM, 0, 10)

    -- Scroll container
    local scrollContainer = WINDOW_MANAGER:CreateControl("FishermansFriendList", window, "ZO_ScrollList")
    scrollContainer:SetAnchor(TOPLEFT, window, TOPLEFT, 20, 50)
    scrollContainer:SetDimensions(500, 300)
    -- End Scroll container

    -- Function to create a fish tile from an itemLink
    local function CreateFishTile(itemLink, count, uid)
        -- Get the fish name and icon from the itemLink
        local fishName = GetItemLinkName(itemLink)
        local fishIcon = GetItemLinkIcon(itemLink)

        -- Create the tile to display the fish
        local controlName = "FishTile_" .. uid
        local tile = CreateControl(controlName, scrollContainer, CT_CONTROL)

        -- Set tile dimensions and position
        tile:SetDimensions(50, 50)

        -- Add the fish name (Text Label)
        local nameLabelName = "FishNameLabel_" .. uid
        local nameLabel = CreateControl(nameLabelName, tile, CT_LABEL)
        nameLabel:SetAnchor(TOP, tile, TOP, 0, 5)
        nameLabel:SetText(fishName .. " x" .. count) -- Display the fish name and count

        -- Add the fish image (Icon)
        local iconName = "FishIcon_" .. uid
        local icon = CreateControl(iconName, tile, CT_TEXTURE) -- CT_TEXTURE creates a texture control
        icon:SetAnchor(TOP, nameLabel, BOTTOM, 0, 5)
        icon:SetTexture(fishIcon) -- Set the texture for the fish icon

        return tile
    end

    function UpdateUI()
        local fishList = {}
        for fish, count in pairs(FishermansFriend.caughtFish) do
            d(fish)
            table.insert(fishList, {
                name = fish,
                count = count,
                rare = RARE_FISH[fish]
            })
        end

        -- Loop through the caughtFish table and create a tile for each fish caught
        local offsetY = 0
        local uid = 0
        for itemLink, count in pairs(FishermansFriend.caughtFish) do
            -- Only display fish items
            local fishTile = CreateFishTile(itemLink, count, uid)
            fishTile:SetAnchor(TOPLEFT, scrollContainer, TOPLEFT, 0, offsetY)

            -- Increment offsetY for the next tile
            offsetY = offsetY + 60 -- Adjust the space between tiles
            uid = uid + 1
        end

        ZO_ScrollList_AddData(scrollList, fishTable)
        ZO_ScrollList_Commit(scrollList)

        levelLabel:SetText(
            "Level: " .. FishermansFriend.level .. " (XP: " .. FishermansFriend.xp .. "/" .. XP_PER_LEVEL .. ")")
    end

    UpdateUI()
end

SLASH_COMMANDS["/fishermansfriend"] = function()
    CreateUI()
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= "FishermansFriend" then
        return
    end
    FishermansFriend = ZO_SavedVars:New("FishermansFriendData", 1, nil, {
        caughtFish = {},
        level = 1,
        xp = 0,
        sortOrder = "name"
    })

    EVENT_MANAGER:RegisterForEvent("FishermansFriend", EVENT_LOOT_RECEIVED, OnLootReceived)
end

EVENT_MANAGER:RegisterForEvent("FishermansFriend", EVENT_ADD_ON_LOADED, OnAddonLoaded)
