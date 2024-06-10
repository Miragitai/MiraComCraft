local basalt = require("..basalt")

local modem = peripheral.wrap("top")
local mon = peripheral.wrap("right")
--Terminal Frame
local main = basalt.createFrame()
-- Monitor Frame
local monitorFrame = basalt.addMonitor():setMonitor(mon):setTheme({FrameBG = colors.black, FrameFG = colors.white})
modem.open(9173)

function capitalize(str)
    return (str:gsub("^.", string.upper):gsub(" .", string.upper))
end
-------------------------------------------------------
local sub = { -- here we create a table where we gonna add some frames
    monitorFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(), -- hide main on start
    monitorFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(), -- Second frame should be visible by default
    monitorFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
}

local function openSubFrame(id) -- we create a function which switches the frame for us
    if(sub[id]~=nil)then
        for k,v in pairs(sub)do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = monitorFrame:addMenubar():setScrollable() -- we create a menubar in our main frame.
    :setSize("parent.w")
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex()) -- here we open the sub frame based on the table index
    end)
    :addItem("Home")
    :addItem("Info")
    :addItem("Null")

----------------------------------------------------------------------------------------------------------------------
-- Main frame - [1]
sub[1]:addLabel()
	:setText(" MiraStorage ")
	:setForeground(colors.red)
	:setBackground(colors.black)
	:setFontSize(2)
    :setPosition(7, 4)
sub[1]:addLabel():setForeground(colors.yellow):setBackground(colors.black)
	:setSize(45,40)
	:setPosition(3, 8)
	:setText("Lorem ipsum dolor sit amet sit eu rebum duo praesent at ipsum facilisis at consectetuer erat labore amet et. Kasd aliquyam voluptua et erat consetetur dolore clita justo. Eos ipsum ut consequat suscipit laoreet. Enim sit iriure dolore labore gubergren ipsum elitr vero ea sit. Vel sed diam invidunt takimata dolor accusam erat amet no elitr autem ut enim eos sadipscing et volutpat sed. Gubergren amet dignissim est nam labore nulla eu erat sed aliquam aliquyam. Hendrerit at gubergren blandit sit sed sea molestie takimata. Est ipsum amet hendrerit nonumy suscipit nonumy et kasd invidunt dolore kasd gubergren. Invidunt lorem vero sit te ipsum. Diam stet et sadipscing velit takimata sadipscing vulputate possim et dolor ipsum et duis ut sanctus et nonumy.")
	
----------------------------------------------------------------------------------------------------------------------
-- Info Frame - [2]

function warnColor(percent, nice, warn, err)
    nice = nice or colors.green
    warn = warn or colors.orange
    err = err or colors.red
    if percent > 60 then
        return nice
    elseif percent > 30 then
        return warn
	else
        return err
    end
end

function getSpaceInfo(message)
    local filledAmount = 0
    local totalLimit = 0
    for i=1, message[1], 2 do
        totalLimit = totalLimit + message[2][i]
    end
    for i=1, #message[3], 2 do
        local count = tonumber(message[3][i]["count"])
        filledAmount = filledAmount + count
    end
    return filledAmount/totalLimit
end

function formatInfoFrameEntry(itemName, itemCount)
    return string.format("+ %s [%s]", itemName, itemCount)
end
function formatNumber(num)
    if (num >= 10000) then
        return string.format("%.1fK",(num / 1000))
    end
    return num
end

local infoLabel = sub[2]:addLabel():setText("?"):setForeground(colors.white):setPosition(2, 2)
sub[2]:addLabel():setText("--------------------------------------------------"):setForeground(colors.gray):setPosition(1, 3)

local storageEntries = {}



----------------------------------------------------------------------------------------------------------------------
-- Third Frame - [3]
sub[3]:addButton():setText("No functionality"):setPosition(2, 4):setSize(18, 3)

----------------------------------------------------------------------------------------------------------------------
-- Mainloop
function mainloop()
    while true do
        -- Info Frame --------------------------------------------------------
    	local a,b,channel,c,message = os.pullEvent("modem_message")
        if channel ~= 9173 then goto continue end
        freeSpacePercent = 100-getSpaceInfo(message)*100
    	infoLabel:setText(string.format("Free Space: %.3f%%", freeSpacePercent)):setForeground(warnColor(freeSpacePercent))
        
        for i=1, #message[3], 2 do
            local pX = 1+25*math.floor(i/40)
            local pY = 4+math.floor(i/2) - math.floor(i/40)*20
            local itemName = capitalize(string.gsub(message[3][i]["name"],".+:",""):gsub("_", " "))
            local itemCount = message[3][i]["count"]
            local maxItemCount = message[2][i]
            if not storageEntries[i] then
	            -- create new label at that position
                storageEntries[i] = sub[2]:addLabel():setForeground(colors.lightBlue):setFontSize(.5) 
                	:setPosition(pX, pY)
                	:setText(formatInfoFrameEntry(itemName, formatNumber(itemCount)))
                	:setForeground(warnColor(100-itemCount/maxItemCount*100, colors.lime, colors.yellow))
            else
                -- label at that position already exists 
                storageEntries[i]:setText(formatInfoFrameEntry(itemName, formatNumber(itemCount)))
                	:setForeground(warnColor(100-itemCount/maxItemCount*100, colors.lime, colors.yellow))
            end
        end
        ----------------------------------------------------------------------
        
        ::continue::
    end
    shell.clear()
    mon.clear()
end

----------------------------------------------------------------------------------------------------------------------
parallel.waitForAny(mainloop, basalt.autoUpdate)
