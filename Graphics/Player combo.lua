local sPlayer = Var "Player"
local c
local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt")
local Pulse = THEME:GetMetric("Combo", "PulseCommand")
local PulseLabel = THEME:GetMetric("Combo", "PulseLabelCommand")

local NumberMinZoom = THEME:GetMetric("Combo", "NumberMinZoom")
local NumberMaxZoom = THEME:GetMetric("Combo", "NumberMaxZoom")
local NumberMaxZoomAt = THEME:GetMetric("Combo", "NumberMaxZoomAt")

local LabelMinZoom = THEME:GetMetric("Combo", "LabelMinZoom")
local LabelMaxZoom = THEME:GetMetric("Combo", "LabelMaxZoom")

local function GetComboSkinFiles()
    local skinName = "default"
    if THEME:GetMetric("Common","UseAdvancedJudgments") then 
        skinName = LoadModule("Config.Load.lua")("SmartJudgments", CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini") or THEME:GetMetric("Common","DefaultJudgment")
    end
    
    local cleanName = string.lower(skinName)
    cleanName = string.match(cleanName, "^(.-)%s*%[") or cleanName
    
    local function searchDir(checkDir)
        local files = FILEMAN:GetDirListing(checkDir, false, false)
        if files and #files > 0 then
            local comboFile, labelFile
            for _, file in ipairs(files) do
                local lowerFile = string.lower(file)
                if string.find(lowerFile, "combo numbers") and string.find(lowerFile, "%.ini$") then
                    comboFile = checkDir .. file
                elseif string.find(lowerFile, "label") or string.find(lowerFile, "combolabel") then
                    labelFile = checkDir .. file
                end
            end
            if comboFile and labelFile then
                return comboFile, labelFile
            end
        end
        return nil
    end

    -- 1. Local theme directory
    local combo, label = searchDir("../JudgmentSkins/" .. cleanName .. "/")
    if combo and label then return combo, label, cleanName end

    -- 2. Global directory
    combo, label = searchDir("/JudgmentSkins/" .. cleanName .. "/")
    if combo and label then return combo, label, cleanName end
    
    return "Combo numbers", "ComboLabel", "default"
end

local comboFont, comboLabel, cleanName = GetComboSkinFiles()

local t = Def.ActorFrame {

    Def.BitmapText {
        Font=comboFont,
        Name="Number",
        OnCommand = function(self) self:valign(0):y(-20) end
    },

    Def.Sprite {
        Texture=comboLabel,
        Name="ComboLabel",
        OnCommand = function(self) self:valign(1):y(-20) end
    },

    InitCommand = function(self)
        -- We'll have to deal with this later
        --self:draworder(notefield_draw_order.over_field)
        c = self:GetChildren()
        c.Number:visible(false)
        c.ComboLabel:visible(false)
    end,

    ComboCommand=function(self, params)
        local iCombo = params.Misses or params.Combo
        if not iCombo or iCombo < ShowComboAt then
            c.Number:visible(false)
            c.ComboLabel:visible(false)
            return
        end

        local minZoom = NumberMinZoom
        local maxZoom = NumberMaxZoom
        local maxZoomAt = NumberMaxZoomAt

        if cleanName ~= "default" then
            minZoom = 0.8
            maxZoom = 1.0
            maxZoomAt = 100
        end

        local Zoom = scale( iCombo, 0, maxZoomAt, minZoom, maxZoom )
        local Zoom = clamp( Zoom, minZoom, maxZoom )

        c.ComboLabel:visible(true)
        c.Number:visible(true)
        c.Number:settext(string.rep("0",3-string.len(iCombo))..iCombo)

        c.Number:stoptweening():diffuse(params.Misses and Color.Red or Color.White)
        :diffusealpha(0.85):zoom(1.25*Zoom):decelerate(0.15):diffusealpha(1.0):zoom(Zoom)
        :sleep(0.35):decelerate(0.3):diffusealpha(0)
        
        c.ComboLabel:stoptweening():diffuse(params.Misses and Color.Red or Color.White)
        :diffusealpha(0.85):zoom(0.75):decelerate(0.15):diffusealpha(1.0):zoom(0.65)
        :sleep(0.35):decelerate(0.3):diffusealpha(0):zoomy(0.4):zoomx(0.85)
    end
}

return t
