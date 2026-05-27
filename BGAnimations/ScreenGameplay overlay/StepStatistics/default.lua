local pNum = GAMESTATE:GetMasterPlayerNumber()
local liveStatsEnabled = LoadModule("Config.Load.lua")("LiveStats", CheckIfUserOrMachineProfile((pNum == PLAYER_1 and 0 or 1)).."/OutFoxPrefs.ini")

-- Disable if 2 players are joined or if the field is centered
local numPlayers = GAMESTATE:GetNumPlayersEnabled()
local isDouble = (GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides")
local isCentered = (isDouble or Center1Player() or GAMESTATE:GetIsFieldCentered(pNum))

if not liveStatsEnabled or numPlayers > 1 or isCentered then 
    return Def.ActorFrame{} 
end

local width = SCREEN_WIDTH / 2
local targetX = (pNum == PLAYER_1) and (SCREEN_WIDTH * 0.75) or (SCREEN_WIDTH * 0.25)

local af = Def.ActorFrame{
    InitCommand=function(self)
        self:x(targetX)
        self:y(SCREEN_CENTER_Y)
    end,
}

-- Background
af[#af+1] = Def.Quad {
    InitCommand=function(self)
        self:zoomto(width, SCREEN_HEIGHT)
        self:diffuse(color("#000000AA"))
    end
}

-- Judgments and Radar counts
af[#af+1] = LoadActor("Judgments")

-- Time Elapsed / Remaining
af[#af+1] = LoadActor("Time")

-- Density Graph
af[#af+1] = LoadActor("DensityGraph", {pNum, width})

return af
