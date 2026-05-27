-- LiveStats.lua
-- Ported 1:1 visually from Simply Love TapNoteJudgments but adapted for Infinitesimal

local pNum = GAMESTATE:GetMasterPlayerNumber()
local liveStatsEnabled = LoadModule("Config.Load.lua")("LiveStats", CheckIfUserOrMachineProfile((pNum == PLAYER_1 and 0 or 1)).."/OutFoxPrefs.ini")

-- Disable if 2 players are joined or if the field is centered
local numPlayers = GAMESTATE:GetNumPlayersEnabled()
local isDouble = (GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides")
local isCentered = (isDouble or Center1Player() or GAMESTATE:GetIsFieldCentered(pNum))

if not liveStatsEnabled or numPlayers > 1 or isCentered then 
    return Def.ActorFrame{} 
end

local row_height = 24
local digits = 4
local pattern = ("%%0%dd"):format(digits)

local TNS = {
    Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
    Judgments = { W1=0, W2=0, W3=0, W4=0, W5=0, Miss=0 },
    Names = { "Fantastic", "Excellent", "Great", "Decent", "Way Off", "Miss" },
    Colors = {
        color("#21cce8"), -- W1 (Blue)
        color("#e8c821"), -- W2 (Gold)
        color("#40e821"), -- W3 (Green)
        color("#b621e8"), -- W4 (Purple)
        color("#e88221"), -- W5 (Orange)
        color("#e82121")  -- Miss (Red)
    }
}

local af = Def.ActorFrame{}
af.Name="TapNoteJudgments"
af.InitCommand=function(self)
    -- Position it where the missing player would be
    local targetX = (pNum == PLAYER_1) and (SCREEN_WIDTH * 0.75) or (SCREEN_WIDTH * 0.25)
    self:x(targetX)
    self:y(SCREEN_CENTER_Y - 40)
    self:zoom(1.0)
end

-- Add dark background behind stats like Simply Love StepStats
af[#af+1] = Def.Quad {
    InitCommand=function(self)
        self:zoomto(260, 320)
        self:diffuse(color("#00000088"))
        self:y(30)
    end
}

-- Banner
af[#af+1] = Def.Sprite {
    InitCommand=function(self)
        self:y(-120)
        self:x(0)
        local song = GAMESTATE:GetCurrentSong()
        if song and song:HasBanner() then
            self:Load(song:GetBannerPath())
            self:scaletofit(-100, -32, 100, 32)
        end
    end
}

for index, window in ipairs(TNS.Types) do
    -- TNS value (The numbers)
    af[#af+1] = LoadFont("Common Normal")..{
        Text=(pattern):format(0),
        InitCommand=function(self)
            self:y((index-1)*row_height - 70)
            self:x(90)
            self:halign(1) -- right align
            self:diffuse( TNS.Colors[index] )
            local leadingZeroAttr = { Length=(digits-1), Diffuse=Brightness(self:GetDiffuse(), 0.35) }
            self:AddAttribute(0, leadingZeroAttr )
        end,
        JudgmentMessageCommand=function(self, params)
            if params.Player ~= pNum then return end
            if params.HoldNoteScore then return end
            if not params.TapNoteScore then return end
            if GAMESTATE:GetPlayerState(pNum):GetPlayerOptions("ModsLevel_Song"):Autoplay() then return end

            local incremented = false
            if ToEnumShortString(params.TapNoteScore) == window then
                TNS.Judgments[window] = TNS.Judgments[window] + 1
                incremented = true
            end

            if incremented then
                self:settext( (pattern):format(TNS.Judgments[window]) )
                local leadingZeroAttr = {
                    Length=(digits - (math.floor(math.log10(math.max(1, TNS.Judgments[window])))+1)),
                    Diffuse=Brightness(TNS.Colors[index], 0.35)
                }
                self:ClearAttributes()
                self:AddAttribute(0, leadingZeroAttr )
            end
        end
    }

    -- TNS label (The words "Fantastic", "Excellent", etc.)
    af[#af+1] = LoadFont("Common Normal")..{
        Text=TNS.Names[index]:upper(),
        InitCommand=function(self)
            self:zoom(0.8)
            self:halign(1) -- right align
            self:x(30)
            self:y((index-1) * row_height - 70)
            self:diffuse( TNS.Colors[index] )
        end,
    }
end

-- Add Holds/Mines/Rolls skeleton to look like Simply Love
local radar_lines = {"Holds", "Mines", "Rolls"}
for i, label in ipairs(radar_lines) do
    af[#af+1] = LoadFont("Common Normal")..{
        Text=label:lower(),
        InitCommand=function(self)
            self:zoom(0.7)
            self:halign(1) -- right align
            self:x(10)
            self:y(85 + (i-1)*24)
            self:diffuse(color("#aaaaaa"))
        end
    }
    af[#af+1] = LoadFont("Common Normal")..{
        Text="000 / 000",
        InitCommand=function(self)
            self:zoom(0.8)
            self:halign(1) -- right align
            self:x(90)
            self:y(85 + (i-1)*24)
            self:diffuse(color("#ffffff"))
        end,
        -- You can expand this to hook into hold note scores!
    }
end

-- Add EX Score (Percent)
af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:y(140)
        self:x(110)
        self:halign(1)
        self:zoom(1.8)
        self:diffuse(color("#ffffff"))
        self:settext("0.00")
    end,
    JudgmentMessageCommand=function(self, params)
        if params.Player ~= pNum then return end
        local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pNum)
        local dp = pss:GetPercentDancePoints() * 100
        self:settext(string.format("%.2f", dp))
    end
}

return af
