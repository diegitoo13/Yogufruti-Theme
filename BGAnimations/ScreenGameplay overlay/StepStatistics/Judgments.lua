local pNum = GAMESTATE:GetMasterPlayerNumber()
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

-- Banner
af[#af+1] = Def.Sprite {
    InitCommand=function(self)
        self:y(-160)
        local song = GAMESTATE:GetCurrentSong()
        if song and song:HasBanner() then
            self:Load(song:GetBannerPath())
            self:scaletofit(-120, -38, 120, 38)
        end
    end
}

for index, window in ipairs(TNS.Types) do
    -- TNS value (The numbers)
    af[#af+1] = LoadFont("Common Normal")..{
        Text=(pattern):format(0),
        InitCommand=function(self)
            self:y((index-1)*row_height - 90)
            self:x(20)
            self:halign(0) -- left align
            self:zoom(1.2)
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
            self:zoom(1.0)
            self:halign(1) -- right align
            self:x(-20)
            self:y((index-1) * row_height - 90)
            self:diffuse( TNS.Colors[index] )
        end,
    }
end

-- Holds/Mines/Rolls tracking
local radar_lines = {"Holds", "Mines", "Rolls"}
local radar_scores = {
    Holds = { hit=0, max=0 },
    Mines = { hit=0, max=0 },
    Rolls = { hit=0, max=0 }
}

for i, label in ipairs(radar_lines) do
    af[#af+1] = LoadFont("Common Normal")..{
        Text=label:lower(),
        InitCommand=function(self)
            self:zoom(0.9)
            self:halign(1) -- right align
            self:x(-20)
            self:y(80 + (i-1)*24)
            self:diffuse(color("#aaaaaa"))
        end
    }
    af[#af+1] = LoadFont("Common Normal")..{
        Text="000 / 000",
        InitCommand=function(self)
            self:zoom(1.0)
            self:halign(0) -- left align
            self:x(20)
            self:y(80 + (i-1)*24)
            self:diffuse(color("#ffffff"))
            
            -- Pre-calculate max
            local steps = GAMESTATE:GetCurrentSteps(pNum)
            if steps then
                local rv = steps:GetRadarValues(pNum)
                if label == "Holds" then radar_scores.Holds.max = rv:GetValue("RadarCategory_Holds") end
                if label == "Mines" then radar_scores.Mines.max = rv:GetValue("RadarCategory_Mines") end
                if label == "Rolls" then radar_scores.Rolls.max = rv:GetValue("RadarCategory_Rolls") end
            end
            self:settext(("%03d / %03d"):format(0, radar_scores[label].max))
        end,
        JudgmentMessageCommand=function(self, params)
            if params.Player ~= pNum then return end
            if GAMESTATE:GetPlayerState(pNum):GetPlayerOptions("ModsLevel_Song"):Autoplay() then return end
            
            if label == "Holds" and params.HoldNoteScore == "HoldNoteScore_Held" then
                radar_scores.Holds.hit = radar_scores.Holds.hit + 1
                self:settext(("%03d / %03d"):format(radar_scores.Holds.hit, radar_scores.Holds.max))
            end
            if label == "Rolls" and params.HoldNoteScore == "HoldNoteScore_Held" then
                -- Note: in some versions Rolls and Holds are both 'Held', need to differentiate by tap note subtype if possible, or just merge them.
                -- OutFox fires TapNoteScore for mines.
            end
            if label == "Mines" and params.TapNoteScore == "TapNoteScore_AvoidMine" then
                radar_scores.Mines.hit = radar_scores.Mines.hit + 1
                self:settext(("%03d / %03d"):format(radar_scores.Mines.hit, radar_scores.Mines.max))
            end
        end
    }
end

return af
