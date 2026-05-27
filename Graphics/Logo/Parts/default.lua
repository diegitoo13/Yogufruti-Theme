return Def.ActorFrame {

    Def.Sprite {
        Texture="Text",
        Name="Text",
        OnCommand=function(self)
            self:queuecommand("Animate")
        end,
        AnimateCommand=function(self)
            self:diffusealpha(0)
            :zoom(1.2)
            :sleep(0.5)
            :diffusealpha(1)
            :glow(1,1,1,1)
            :easeoutexpo(1)
            :zoom(1)
            :glow(1,1,1,0)
        end
    },

    Def.Sprite {
        Texture="Text",
        Name="Text_Mask",
        InitCommand=function(self)
            self:MaskSource()
        end
    },

    Def.Quad {
        Name="Text_Shine",
        OnCommand=function(self)
            self:queuecommand("Animate")
        end,
        AnimateCommand=function(self)
            self:zoomto(80, 400)
            :diffuse(1,1,1,0.75)
            :skewx(-1)
            :x(-535)
            :MaskDest():ztestmode("ZTestMode_WriteOnFail")
            :sleep(0.8)
            :linear(0.5)
            :x(535)
        end
    },

}
