local sPlayer = Var "Player"

local function GetTexture()
    local skinName = "default"
    if THEME:GetMetric("Common","UseAdvancedJudgments") then 
        if GAMESTATE:IsDemonstration() then
            skinName = THEME:GetMetric("Common","DefaultJudgment")
        else
            skinName = LoadModule("Config.Load.lua")("SmartJudgments", CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini") or THEME:GetMetric("Common","DefaultJudgment")
        end
    end
    
    local cleanName = string.lower(skinName)
    cleanName = string.match(cleanName, "^(.-)%s*%[") or cleanName
    
    local function searchDir(checkDir)
        local files = FILEMAN:GetDirListing(checkDir, false, false)
        if files and #files > 0 then
            for _, file in ipairs(files) do
                if string.find(string.lower(file), "judgment") then
                    return checkDir .. file
                end
            end
        end
        return nil
    end

    -- 1. Local theme directory
    local file = searchDir("../JudgmentSkins/" .. cleanName .. "/")
    if file then return file end

    -- 2. Global directory
    file = searchDir("/JudgmentSkins/" .. cleanName .. "/")
    if file then return file end

    if THEME:GetMetric("Common","UseAdvancedJudgments") then 
        if GAMESTATE:IsDemonstration() then
            return LoadModule("Options.SmartJudgments.lua")()[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),THEME:GetMetric("Common","DefaultJudgment"))] 
        end
        return LoadModule("Options.SmartJudgments.lua")()[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),LoadModule("Config.Load.lua")("SmartJudgments",CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini") or THEME:GetMetric("Common","DefaultJudgment"))] 
    end
    return THEME:GetPathG("Judgment","Normal")
end
local bProtiming = LoadModule("Config.Load.lua")("ProTiming",CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini")
local bOffsetBar = LoadModule("Config.Load.lua")("OffsetBar",CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini")
local bHideJudgment = LoadModule("Config.Load.lua")("HideJudgment",CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini") or false

local Name,Length = LoadModule("Options.SmartTapNoteScore.lua")()
table.sort(Name)
Name[#Name+1] = "Miss"
Length = Length + 1

local DoubleSet = Length*2

local OffbarPos = bHideJudgment and 0 or -32

local AddZoom = string.find(GetTexture(), "Infinitesimal") and 1.25 or 1

-- Generate Offset Bar
local OffBar = Def.ActorFrame{ InitCommand=function(self) self:visible(bOffsetBar) end,
    Def.ActorFrame {
        Name="Background",
        OnCommand=function(s) s:visible(false) end,
        Def.Quad { OnCommand=function(self) self:zoomto(150,1):fadeleft(1):faderight(1) end },
        Def.Quad { OnCommand=function(self) self:zoomto(2,32):fadetop(1):fadebottom(1) end }
    }
}
OffBar[#OffBar+1] = Def.Quad { InitCommand=function(self) self:zoomto(2,15):diffusealpha(0):shadowlength(1) end }

return Def.ActorFrame {
    Def.Sprite {
        Name="Judgment",
        Texture=GetTexture(),
        InitCommand=function(self) self:pause():visible(false) end,
        ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end
    },
    
    LoadFont("Montserrat extrabold 20px") .. {
        Name="Protiming",
        Text="",
        InitCommand=function(self) self:visible(false) end,
        OnCommand=function(self) self:y(OffbarPos - 20):zoom(0.5):shadowlength(1) end,
    },
    
    OffBar .. { Name="OffsetBar", OnCommand=function(self) self:y(OffbarPos) end },
    
    JudgmentMessageCommand=function(self, params)
        local Judg = self:GetChild("Judgment")
        local Prot = self:GetChild("Protiming")
        local OFB = self:GetChild("OffsetBar")
        if params.Player ~= sPlayer then return end
        local sScore = params.TapNoteScore and tostring(params.TapNoteScore) or ""
        if params.HoldNoteScore or sScore == "TapNoteScore_CheckpointHit" then return end
        if string.find(sScore, "Mine") then return end
        if self:GetName() ~= "Judgment" then
            if IsGame("po-mu") then
                if PomuLocation[GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()][params.FirstTrack] ~= tonumber(ToEnumShortString(self:GetName())) then return end
            else
                if params.FirstTrack ~= tonumber(ToEnumShortString(self:GetName())) then return end
            end
        end

        local jPath = string.match(Judg:GetTexture():GetPath(), ".*/(.*)")
        local iFrame
        local iNumFrames = Judg:GetTexture():GetNumFrames()
        local IsDouble = string.find(jPath, "%[double%]")
        -- Check if the current texture is a double sided judgment texture.
        -- lua.ReportScriptError( iNumFrames .. " - " .. DoubleSet )
        if iNumFrames == DoubleSet then
            IsDouble = true
        end

        if iNumFrames == 7 then
            local mapping = {
                TapNoteScore_W1 = 0,
                TapNoteScore_W2 = 3,
                TapNoteScore_W3 = 2,
                TapNoteScore_W4 = 4,
                TapNoteScore_W5 = 4,
                TapNoteScore_Miss = 5,
                TapNoteScore_CheckpointMiss = 5,
                TapNoteScore_CheckpointHit = 6,
            }
            iFrame = mapping[sScore]
        else
            for i = 1,#Name do
                if sScore == "TapNoteScore_"..Name[i] then iFrame = i-1 end
            end

            if sScore == "TapNoteScore_Miss" or 
            sScore == "TapNoteScore_CheckpointMiss" then
                iFrame = (IsDouble and (iNumFrames * .5) or iNumFrames)-1
            end
            
            if sScore == "TapNoteScore_CheckpointHit" then iFrame = 0 end
        end

        if not iFrame then return end
        if IsDouble then
            iFrame = iFrame * 2
            if not params.Early then
                iFrame = iFrame + 1
            end
        end

        self:playcommand("Reset")

        Judg:visible(not bHideJudgment):setstate(iFrame)
        :stoptweening():zoom(0.85 * AddZoom):diffusealpha(0.75):decelerate(0.15)
        :zoom(0.70 * AddZoom):diffusealpha(1):sleep(0.35):decelerate(0.3)
        :diffusealpha(0):zoomy(0.4 * AddZoom):zoomx(0.85 * AddZoom)
        
        Prot:visible(bProtiming)
        OFB:GetChild("Background"):visible(bOffsetBar)
        
        if not (sScore == "TapNoteScore_CheckpointHit" or sScore == "TapNoteScore_CheckpointMiss" or sScore == "TapNoteScore_Miss" ) then
            
            -- Manage MS timing
            Prot:finishtweening():diffusealpha(1)
            :settext( math.floor(params.TapNoteOffset * 1000) .. " ms")
            :sleep(0.5):decelerate(0.3):diffusealpha(0)

            -- Manage Offset Bar
            if bOffsetBar then
                OFB:GetChild("Background"):finishtweening():diffuse(Color.White)
                OFB:GetChild(""):finishtweening():diffuse(Color.White)
                :decelerate(0.1):x(math.floor(params.TapNoteOffset * 600)) 
                :sleep(0.4):decelerate(0.3):diffusealpha(0)
                OFB:GetChild("Background"):sleep(0.4):decelerate(0.3):diffusealpha(0)
            end
        end
    end
}
