-- LiveStats.lua
-- Ported 1:1 visually from Simply Love TapNoteJudgments but adapted for Infinitesimal

local pNum = GAMESTATE:GetMasterPlayerNumber()
local liveStatsEnabled = LoadModule("Config.Load.lua")("LiveStats", CheckIfUserOrMachineProfile((pNum == PLAYER_1 and 0 or 1)).."/OutFoxPrefs.ini")

if not liveStatsEnabled then return Def.ActorFrame{} end

local row_height = 35
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
    -- Position it like Simply Love does (Side of the playfield)
    local isCentered = (GetNotefieldX(pNum) == _screen.cx)
    if isCentered then
        self:x( pNum==PLAYER_1 and (_screen.w * 0.15) or (_screen.w * 0.85) )
    else
        self:x( pNum==PLAYER_1 and (_screen.w * 0.75) or (_screen.w * 0.25) )
    end
    self:y(_screen.cy)
    self:zoom(0.8)
end

-- Add dark background behind stats like Simply Love StepStats
af[#af+1] = Def.Quad {
    InitCommand=function(self)
        self:zoomto(160, 240)
        self:diffuse(color("#00000088"))
        self:y( -70 + (2.5 * row_height) )
    end
}

for index, window in ipairs(TNS.Types) do

    -- TNS value (The numbers)
    af[#af+1] = LoadFont("Common Normal")..{
        Text=(pattern):format(0),
        InitCommand=function(self)
            self:zoom(1.0)
            self:y((index-1)*row_height - 70)
            self:x(30)
            self:halign(1) -- right align
            
            self:diffuse( TNS.Colors[index] )
            -- Add leading zero attributes (grayed out)
            local leadingZeroAttr = { Length=(digits-1), Diffuse=Brightness(self:GetDiffuse(), 0.35) }
            self:AddAttribute(0, leadingZeroAttr )
        end,
        JudgmentMessageCommand=function(self, params)
            if params.Player ~= pNum then return end
            if params.HoldNoteScore then return end
            if not params.TapNoteScore then return end
            if IsAutoplay(pNum) then return end

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
            self:zoom(0.833):maxwidth(72)
            self:halign( 0 ) -- left align
            self:x(-60)
            self:y((index-1) * row_height - 70)
            self:diffuse( TNS.Colors[index] )
        end,
    }
end

-- Add EX Score (Percent)
af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:y(-100)
        self:zoom(1.2)
        self:diffuse(color("#ffffff"))
        self:settext("0.00%")
    end,
    JudgmentMessageCommand=function(self, params)
        if params.Player ~= pNum then return end
        local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pNum)
        local dp = pss:GetPercentDancePoints() * 100
        self:settext(string.format("%.2f%%", dp))
    end
}

return af
