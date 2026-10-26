--[[
=====================================================================================================
    BABIS UI  v2.8 — SURVIVE THE HULK + BABIS TOOLS
=====================================================================================================
    v2.8: game logic wrapped in a closure — fixes "Out of local registers" (limit 200)
    No sounds. Hardened init.
=====================================================================================================
]]

print("[Babis] start")

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local Workspace        = game:GetService("Workspace")
local Debris           = game:GetService("Debris")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local genv = _G
do
    local ok, g = pcall(function() return getgenv() end)
    if ok and type(g) == "table" then genv = g end
end

if type(genv.BabisUnload) == "function" then pcall(genv.BabisUnload) end

local uiParent = PlayerGui
pcall(function()
    if gethui then
        local h = gethui()
        if h then uiParent = h end
    end
end)

pcall(function() RunService:UnbindFromRenderStep("BabisAntiRagdoll") end)

for _, holder in ipairs({ uiParent, PlayerGui }) do
    for _, n in ipairs({
        "BabisUIKitNotif", "MeuRetangulo", "BabisConfirmDialog",
        "BabisKillOverlay", "BabisClimbOverlay", "BabisHulkAlert",
        "BabisEventLog", "BabisIntro", "BabisPanicFloat", "BabisFlingFloat",
    }) do
        local o = holder:FindFirstChild(n)
        if o then o:Destroy() end
    end
end

local FONT_MAIN   = Enum.Font.GothamBold
local FONT_STRONG = Enum.Font.GothamBlack
local FONT_CODE   = Enum.Font.Code

local DISCORD_ICON   = "rbxassetid://100770414662869"
local DISCORD_TINT   = Color3.fromRGB(115, 136, 217)
local DISCORD_URL    = "https://discord.gg/ZvCwj68e"
local CHECK_ICON     = "rbxassetid://111774854328409"
local LOGO_ICON      = "rbxassetid://88981628950457"
local LOGO_BALL_ICON = "rbxassetid://78039301847826"
local CLICK_ICON     = "rbxassetid://88060480140568"
local BELL_ICON      = "rbxassetid://7072706001"
local ARROW_ICON     = "rbxassetid://7734034764"
local MIN_ICON       = "rbxassetid://7734000129"
local CLOSE_ICON     = "rbxassetid://7743878857"

local SUBTITLE_TEXT = "Survive The Hulk"
local PREMIUM_TEXT  = "Premium version"
local LOGO_CONFIG   = { width = 155, height = 74.7, posX = -22, posY = -3, rotation = 0.1 }

local DESIGN_W, DESIGN_H = 720, 470
local HEADER_H   = 60
local SIDEBAR_W  = 140
local CORNER     = 20
local CARD_H     = 42
local BALL       = 62

local winW, winH           = DESIGN_W, DESIGN_H
local MIN_W, MIN_H         = 500, 380
local MAX_W, MAX_H         = DESIGN_W * 2, DESIGN_H * 2

local TEXT       = Color3.fromRGB(230, 230, 235)
local TEXT_DIM   = Color3.fromRGB(150, 150, 158)
local TEXT_MUTED = Color3.fromRGB(120, 120, 128)
local WHITE      = Color3.new(1, 1, 1)
local BLACK      = Color3.new(0, 0, 0)
local C_SUCCESS  = Color3.fromRGB(80, 220, 120)
local C_ERROR    = Color3.fromRGB(235, 85, 85)
local C_WARN     = Color3.fromRGB(255, 190, 60)
local C_LOCKED   = Color3.fromRGB(90, 90, 100)

local DEFAULT_FLING_SPEED = 400
local FLING_SPIN_MULT     = 30

local alive = true
local conns = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local function new(class, props)
    local o = Instance.new(class)
    local parent
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then parent = v else o[k] = v end
        end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = p }) end
local function stroke(p, col, th, tr)
    return new("UIStroke", {
        Color = col, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p,
    })
end
local function tween(o, props, d, style, dir)
    local t = TweenService:Create(o, TweenInfo.new(d or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end
local function apply(o, props, d, style, dir)
    if d and d > 0 then return tween(o, props, d, style, dir) end
    for k, v in pairs(props) do o[k] = v end
end

local function newLabel(parent, text, size, font, color, props)
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size, Font = font,
        TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = parent,
    })
    if props then for k, v in pairs(props) do l[k] = v end end
    return l
end

local function playSound() end -- sounds disabled

local function safeWrite(inst, prop, value) inst[prop] = value end
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local function hsvToRgb(h, s, v)
    h = h % 360
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return Color3.new(r + m, g + m, b + m)
end

local function rgbToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == r then h = 60 * (((g - b) / d) % 6)
        elseif mx == g then h = 60 * ((b - r) / d + 2)
        else h = 60 * ((r - g) / d + 4) end
    end
    return h, (mx > 0 and (d / mx) or 0), mx
end

local function toHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function derive(t)
    t.hover    = t.bgCard:Lerp(WHITE, 0.035)
    t.trackOff = t.bgCard:Lerp(WHITE, 0.08)
    return t
end

local ORIGINAL_THEME = derive({
    accent     = Color3.fromRGB(74, 158, 255),
    glow       = Color3.fromRGB(120, 185, 255),
    border     = Color3.fromRGB(38, 38, 44),
    textActive = Color3.fromRGB(74, 158, 255),
    bgMain     = Color3.fromRGB(9, 9, 11),
    bgHeader   = Color3.fromRGB(13, 13, 16),
    bgCard     = Color3.fromRGB(13, 13, 16),
})

local function makeTheme(base)
    local glow = Color3.new(math.min(1, base.R * 0.5 + 0.5), math.min(1, base.G * 0.5 + 0.5), math.min(1, base.B * 0.5 + 0.5))
    local border = Color3.new(math.clamp(base.R * 0.3 + 0.05, 0, 1), math.clamp(base.G * 0.3 + 0.05, 0, 1), math.clamp(base.B * 0.3 + 0.05, 0, 1))
    local brightness = base.R * 0.299 + base.G * 0.587 + base.B * 0.114
    return derive({
        accent = base, glow = glow, border = border,
        textActive = brightness > 0.4 and base or glow,
        bgMain   = Color3.new(0.03 + base.R * 0.05, 0.03 + base.G * 0.05, 0.04 + base.B * 0.05),
        bgHeader = Color3.new(0.04 + base.R * 0.06, 0.04 + base.G * 0.06, 0.05 + base.B * 0.06),
        bgCard   = Color3.new(0.04 + base.R * 0.06, 0.04 + base.G * 0.06, 0.05 + base.B * 0.06),
    })
end

local function colorMatch(c1, c2, tol)
    tol = tol or 0.02
    return math.abs(c1.R - c2.R) < tol and math.abs(c1.G - c2.G) < tol and math.abs(c1.B - c2.B) < tol
end

local Theme = { c = ORIGINAL_THEME, regs = {} }
function Theme.reg(inst, fn)
    Theme.regs[#Theme.regs + 1] = { inst = inst, fn = fn }
    fn(Theme.c, false)
end
function Theme.bind(inst, prop, role)
    Theme.reg(inst, function(c, animate)
        if animate then tween(inst, { [prop] = c[role] }, 0.35, Enum.EasingStyle.Quad)
        else inst[prop] = c[role] end
    end)
end

local setOption
function Theme.set(color)
    if typeof(color) ~= "Color3" then return end
    local newT = colorMatch(color, ORIGINAL_THEME.accent, 0.004) and ORIGINAL_THEME or makeTheme(color)
    Theme.c = newT
    if setOption then setOption("theme_color", newT.accent) end
    genv.BabisThemeColor = newT.accent
    for i = #Theme.regs, 1, -1 do
        local r = Theme.regs[i]
        if r.inst and not r.inst.Parent then table.remove(Theme.regs, i)
        else pcall(r.fn, newT, true) end
    end
end

genv.BabisESPColor = genv.BabisESPColor or Color3.fromRGB(230, 30, 30)

local DEFAULTS = {
    theme_color = ORIGINAL_THEME.accent,
    auto_load_config = false,
    last_selected_config = "",
    esp_color = genv.BabisESPColor,
}

genv.BabisOptions = genv.BabisOptions or {}
local Options = genv.BabisOptions
for k, v in pairs(DEFAULTS) do
    if Options[k] == nil then Options[k] = v end
end
if typeof(Options.esp_color) ~= "Color3" then Options.esp_color = DEFAULTS.esp_color end
if typeof(Options.theme_color) ~= "Color3" then Options.theme_color = DEFAULTS.theme_color end

local ChangedEvent = Instance.new("BindableEvent")
genv.BabisOptionChanged = ChangedEvent.Event
setOption = function(key, value)
    Options[key] = value
    pcall(function() ChangedEvent:Fire(key, value) end)
end

local Registry = {}

local CFG = { root = "Babis", folder = "Babis/configs", ext = ".json", autoload = "Babis/autoload.txt" }
local ConfigSys = {}

function ConfigSys.canWrite()
    return type(writefile) == "function" and type(readfile) == "function"
end
function ConfigSys.ensure()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
    pcall(function()
        if not isfolder(CFG.root) then makefolder(CFG.root) end
        if not isfolder(CFG.folder) then makefolder(CFG.folder) end
    end)
end
function ConfigSys.sanitize(name)
    name = tostring(name or "")
    name = name:gsub("[%c\\/:*?\"<>|]", "")
    name = name:match("^%s*(.-)%s*$") or ""
    return name:sub(1, 32)
end
function ConfigSys.list()
    ConfigSys.ensure()
    local out = {}
    if type(listfiles) ~= "function" then return out end
    local ok, files = pcall(listfiles, CFG.folder)
    if not ok or type(files) ~= "table" then return out end
    for _, path in ipairs(files) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end
function ConfigSys.exists(name)
    for _, n in ipairs(ConfigSys.list()) do if n:lower() == name:lower() then return true end end
    return false
end
function ConfigSys.save(name, data)
    if not ConfigSys.canWrite() then return false end
    ConfigSys.ensure()
    if type(name) ~= "string" or name == "" then return false end
    local okEnc, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if not okEnc then return false end
    return pcall(writefile, CFG.folder .. "/" .. name .. CFG.ext, enc)
end
function ConfigSys.load(name)
    if type(readfile) ~= "function" then return nil end
    local okR, content = pcall(readfile, CFG.folder .. "/" .. name .. CFG.ext)
    if not okR or type(content) ~= "string" then return nil end
    local okD, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not okD or type(data) ~= "table" then return nil end
    return data
end
function ConfigSys.delete(name)
    if type(delfile) ~= "function" then return false end
    return pcall(delfile, CFG.folder .. "/" .. name .. CFG.ext)
end
function ConfigSys.writeAutoload(enabled, name)
    if not ConfigSys.canWrite() then return end
    ConfigSys.ensure()
    pcall(function() writefile(CFG.autoload, HttpService:JSONEncode({ enabled = enabled == true, config = name or "" })) end)
end
function ConfigSys.readAutoload()
    if type(readfile) ~= "function" then return nil end
    local ok, content = pcall(readfile, CFG.autoload)
    if not ok or type(content) ~= "string" then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if ok2 and type(data) == "table" then return data end
    return nil
end

local PERSIST_KEYS = {
    "theme_color", "auto_load_config", "last_selected_config",
    "esp_color", "esp_player",
    "infinite_stamina", "jump_enabled", "jump_value",
    "tpwalk_enabled", "tp_speed", "anti_ragdoll",
    "auto_escape", "auto_kill_hulk", "fling_predict", "fling_speed",
    "auto_punch",
    "esp_hulk", "esp_hulkbuster", "esp_survivor", "esp_weapons",
    "esp_vents", "esp_cabinet", "esp_ability", "esp_hulk_chance",
    "hulk_alert", "live_event",
    "anti_debris", "remove_doors", "auto_mission",
}

local function serializeOptions()
    local safe = {}
    for _, k in ipairs(PERSIST_KEYS) do
        local v = Options[k]
        if typeof(v) == "Color3" then safe[k] = { R = v.R, G = v.G, B = v.B } else safe[k] = v end
    end
    return safe
end
local function parseColor(v)
    if type(v) == "table" and type(v.R) == "number" and type(v.G) == "number" and type(v.B) == "number" then
        return Color3.new(math.clamp(v.R, 0, 1), math.clamp(v.G, 0, 1), math.clamp(v.B, 0, 1))
    end
    return nil
end
local function deserializeOptions(data)
    local applied = {}
    for _, k in ipairs(PERSIST_KEYS) do
        local v = data[k]
        if v ~= nil then
            local good
            if k == "esp_color" or k == "theme_color" then good = parseColor(v)
            elseif type(v) == "boolean" or type(v) == "string" or type(v) == "number" then good = v end
            if good ~= nil then setOption(k, good); applied[k] = true end
        end
    end
    return applied
end

local NOTIF_W = 270
local Notifier = {}
do
    local notifGui = new("ScreenGui", {
        Name = "BabisUIKitNotif", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 300, Parent = uiParent,
    })
    local container = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0, NOTIF_W, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16), Parent = notifGui,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = container,
    })

    local order, active = 0, {}
    local KIND = { success = C_SUCCESS, error = C_ERROR, warn = C_WARN }

    local function dismiss(row)
        if not row or not row.Parent or row:GetAttribute("Dismissing") then return end
        row:SetAttribute("Dismissing", true)
        local card = row:FindFirstChild("Card")
        if card then
            tween(card, { Position = UDim2.new(1, NOTIF_W + 40, 0, 0), GroupTransparency = 1 }, 0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        end
        task.delay(0.2, function() if row and row.Parent then tween(row, { Size = UDim2.new(1, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quint) end end)
        task.delay(0.5, function() if row and row.Parent then row:Destroy() end end)
    end

    function Notifier.notify(title, message, duration, kind)
        title = tostring(title or "Notification")
        message = tostring(message or "")
        duration = tonumber(duration) or 2.5
        order = order + 1

        local col = KIND[kind or "info"] or Theme.c.accent
        local textW = NOTIF_W - 78
        local msgH = 14
        pcall(function() msgH = TextService:GetTextSize(message, 11, FONT_MAIN, Vector2.new(textW, 1000)).Y end)
        local height = math.max(58, 14 + 18 + msgH + 16)

        local row = new("Frame", { Name = "Row", Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = order, Parent = container })
        local card = new("CanvasGroup", {
            Name = "Card", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, NOTIF_W + 40, 0, 0),
            BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, GroupTransparency = 0.4, Parent = row,
        })
        corner(card, 12)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(208, 208, 214)), Parent = card })

        local bf = new("Frame", { Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = card })
        corner(bf, 11); stroke(bf, Theme.c.border, 1, 0.05)

        local bar = new("Frame", { Size = UDim2.new(0, 4, 1, -20), Position = UDim2.new(0, 8, 0, 10), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(bar, 2)

        local iconBg = new("Frame", { Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 20, 0.5, -16), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(iconBg, 16); stroke(iconBg, col, 1, 0.35)
        new("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0.5, -9, 0.5, -9), BackgroundTransparency = 1,
            Image = BELL_ICON, ImageColor3 = col:Lerp(WHITE, 0.35), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = iconBg,
        })

        newLabel(card, title, 13, FONT_MAIN, TEXT, { Size = UDim2.new(1, -78, 0, 18), Position = UDim2.new(0, 62, 0, 10), TextTruncate = Enum.TextTruncate.AtEnd })
        newLabel(card, message, 11, FONT_MAIN, TEXT_DIM, { Size = UDim2.new(1, -78, 0, msgH), Position = UDim2.new(0, 62, 0, 29), TextWrapped = true })

        local progBg = new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.c.border, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        local prog = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 4, Parent = progBg })

        local hit = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20, Parent = card })
        local hovering = false
        hit.MouseEnter:Connect(function() hovering = true end)
        hit.MouseLeave:Connect(function() hovering = false end)
        hit.MouseButton1Click:Connect(function() dismiss(row) end)

        for i = #active, 1, -1 do if not active[i].Parent then table.remove(active, i) end end
        active[#active + 1] = row
        while #active > 5 do dismiss(active[1]); table.remove(active, 1) end

        tween(card, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Back)

        task.spawn(function()
            local remaining = duration
            local last = os.clock()
            while remaining > 0 and row.Parent and not row:GetAttribute("Dismissing") do
                task.wait(0.03)
                local now = os.clock(); local dt = now - last; last = now
                if not hovering then remaining = remaining - dt end
                if prog.Parent then prog.Size = UDim2.new(math.max(0, remaining / duration), 0, 1, 0) end
            end
            dismiss(row)
        end)
        return row
    end
    function Notifier.destroy() pcall(function() notifGui:Destroy() end) end
end
_G.BabisNotify = Notifier.notify
genv.BabisNotify = Notifier.notify
local function notify(title, msg, dur, kind) Notifier.notify(title, msg, dur, kind) end

local Confirm = {}
do
    local cgui = new("ScreenGui", {
        Name = "BabisConfirmDialog", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 900, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PlayerGui,
    })
    local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Parent = cgui })
    local panel = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(250, 150), BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Parent = cgui })
    corner(panel, 14)
    local pScale = new("UIScale", { Scale = 0.85, Parent = panel })
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 205, 212)), Parent = panel })
    local pb = new("Frame", { Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = panel })
    corner(pb, 13); stroke(pb, Theme.c.border, 1.2, 0)

    newLabel(panel, "HE IS SURE?", 19, FONT_STRONG, TEXT, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2 })
    local subLbl = newLabel(panel, "", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 12, 0, 52), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2 })

    local btnRow = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(176, 40), BackgroundTransparency = 1, ZIndex = 3, Parent = panel })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = btnRow })

    local function mkBtn(text, size, color, order)
        local b = new("TextButton", { LayoutOrder = order, Size = UDim2.fromOffset(82, 40), BackgroundColor3 = Theme.c.bgMain, Text = text, Font = FONT_STRONG, TextSize = size, TextColor3 = color, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = btnRow })
        corner(b, 10)
        local s = stroke(b, Theme.c.border, 1, 0)
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.c.hover }, 0.12); tween(s, { Color = color }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.c.bgMain }, 0.15); tween(s, { Color = Theme.c.border }, 0.15) end)
        return b
    end
    local noBtn  = mkBtn("✕", 18, C_ERROR, 1)
    local yesBtn = mkBtn("✓", 22, Theme.c.accent, 2)

    local isOpen, onYes, onNo = false, nil, nil
    local token = 0
    local function hide()
        if not isOpen then return end
        isOpen = false; token = token + 1
        tween(dim, { BackgroundTransparency = 1 }, 0.18)
        tween(panel, { GroupTransparency = 1 }, 0.16)
        tween(pScale, { Scale = 0.88 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local my = token
        task.delay(0.2, function() if token == my and cgui.Parent then dim.Visible = false; panel.Visible = false end end)
    end
    function Confirm.ask(text, sub, yesFn, noFn)
        onYes, onNo = yesFn, noFn
        subLbl.Text = sub or ""
        isOpen = true; token = token + 1
        dim.Visible = true; panel.Visible = true
        dim.BackgroundTransparency = 1; panel.GroupTransparency = 1; pScale.Scale = 0.85
        tween(dim, { BackgroundTransparency = 0.5 }, 0.25)
        tween(panel, { GroupTransparency = 0 }, 0.2)
        tween(pScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
    end
    noBtn.MouseButton1Click:Connect(function() local f = onNo; hide(); if f then f() end end)
    yesBtn.MouseButton1Click:Connect(function() local f = onYes; hide(); if f then task.delay(0.12, f) end end)
    dim.MouseButton1Click:Connect(function() local f = onNo; hide(); if f then f() end end)
    bind(UserInputService.InputBegan, function(input)
        if not isOpen then return end
        if input.KeyCode == Enum.KeyCode.Escape then local f = onNo; hide(); if f then f() end
        elseif input.KeyCode == Enum.KeyCode.Return then local f = onYes; hide(); if f then task.delay(0.12, f) end end
    end)
    function Confirm.destroy() pcall(function() cgui:Destroy() end) end
end

local gui = new("ScreenGui", {
    Name = "MeuRetangulo", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100, Enabled = true,
    Parent = PlayerGui,
})

local root = new("Frame", { Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(winW, winH), BackgroundTransparency = 1, Parent = gui })
local fitScale = new("UIScale", { Parent = root })

local function viewport()
    if gui then local s = gui.AbsoluteSize; if s.X >= 50 and s.Y >= 50 then return s end end
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function updateFit()
    local vp = gui.AbsoluteSize
    if vp.X < 50 or vp.Y < 50 then vp = viewport() end
    fitScale.Scale = math.clamp(math.min(vp.X * 0.92 / winW, vp.Y * 0.90 / winH), 0.5, 1.25)
end
updateFit()
bind(gui:GetPropertyChangedSignal("AbsoluteSize"), updateFit)

local shadowLayers = {}
for i = 1, 7 do
    local s = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8), Size = UDim2.new(1, i * 7, 1, i * 7), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Parent = root })
    corner(s, CORNER + i * 3)
    shadowLayers[i] = s
end
local function setShadow(visible, d)
    for i, s in ipairs(shadowLayers) do
        apply(s, { BackgroundTransparency = visible and (0.9 + i * 0.0075) or 1 }, d or 0.4, Enum.EasingStyle.Quad)
    end
end

local canvas = new("CanvasGroup", { Name = "Canvas", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 1, Parent = root })
corner(canvas, CORNER); Theme.bind(canvas, "BackgroundColor3", "bgMain")
local popScale = new("UIScale", { Scale = 0.86, Parent = canvas })
new("UIGradient", { Rotation = 135, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(208, 208, 218)), Parent = canvas })

local borderFrame = new("Frame", { Name = "Border", Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1), BackgroundTransparency = 1, ZIndex = 60, Parent = canvas })
corner(borderFrame, CORNER - 1)
local borderStroke = stroke(borderFrame, Theme.c.border, 1.2, 0.05)
Theme.bind(borderStroke, "Color", "border")

local overlay = new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100, Parent = canvas })

local grip = new("TextButton", { Name = "ResizeGrip", Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 65, Parent = canvas })
local gripDots = {}
for _, d in ipairs({ {14,14}, {8,14}, {14,8}, {2,14}, {8,8}, {14,2} }) do
    local dot = new("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(d[1], d[2]), BackgroundColor3 = TEXT_MUTED, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 66, Parent = grip })
    corner(dot, 1); gripDots[#gripDots + 1] = dot
end
grip.MouseEnter:Connect(function() for _, d in ipairs(gripDots) do tween(d, { BackgroundColor3 = Theme.c.accent, BackgroundTransparency = 0 }, 0.12) end end)
grip.MouseLeave:Connect(function() for _, d in ipairs(gripDots) do tween(d, { BackgroundColor3 = TEXT_MUTED, BackgroundTransparency = 0.3 }, 0.15) end end)

local function ripple(card, input)
    local sc = fitScale.Scale
    local abs = card.AbsolutePosition
    local size = card.AbsoluteSize
    local x, y = size.X / sc / 2, size.Y / sc / 2
    if input and input.Position then x = (input.Position.X - abs.X) / sc; y = (input.Position.Y - abs.Y) / sc end
    local r = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 2, Parent = card })
    corner(r, 999)
    local d = (size.X / sc) * 2.2
    tween(r, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.6, Enum.EasingStyle.Quart)
    Debris:AddItem(r, 0.7)
end

local Tooltip = {}
do
    local tip = new("TextLabel", { Name = "Tooltip", BackgroundColor3 = Theme.c.bgMain, BackgroundTransparency = 1, TextTransparency = 1, Font = FONT_MAIN, TextSize = 11, TextColor3 = TEXT, Text = "", BorderSizePixel = 0, ZIndex = 200, Size = UDim2.fromOffset(60, 22), AnchorPoint = Vector2.new(0.5, 0), Visible = false, Parent = overlay })
    corner(tip, 6)
    local tStroke = stroke(tip, Theme.c.border, 1, 1)
    local token = 0
    function Tooltip.show(text, anchor)
        token = token + 1; local my = token
        task.delay(0.35, function()
            if token ~= my or not anchor.Parent then return end
            local sc = fitScale.Scale
            local w = 60
            pcall(function() w = TextService:GetTextSize(text, 11, FONT_MAIN, Vector2.new(400, 30)).X + 18 end)
            local a, o = anchor.AbsolutePosition, overlay.AbsolutePosition
            local cx = (a.X - o.X) / sc + anchor.AbsoluteSize.X / sc / 2
            local y = (a.Y - o.Y) / sc + anchor.AbsoluteSize.Y / sc + 8
            cx = math.clamp(cx, w / 2 + 6, winW - w / 2 - 6)
            tip.Text = text; tip.Size = UDim2.fromOffset(w, 22); tip.Position = UDim2.fromOffset(cx, y + 4)
            tip.BackgroundColor3 = Theme.c.bgMain; tStroke.Color = Theme.c.border
            tip.Visible = true
            tween(tip, { Position = UDim2.fromOffset(cx, y), BackgroundTransparency = 0.05, TextTransparency = 0 }, 0.15)
            tween(tStroke, { Transparency = 0.2 }, 0.15)
        end)
    end
    function Tooltip.hide()
        token = token + 1
        tween(tip, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.1)
        tween(tStroke, { Transparency = 1 }, 0.1)
        local my = token
        task.delay(0.12, function() if token == my then tip.Visible = false end end)
    end
end

local Popup = { current = nil }
function Popup.close()
    local cur = Popup.current; if not cur then return end
    Popup.current = nil
    if cur.arrow and cur.arrow.Parent then tween(cur.arrow, { Rotation = 0 }, 0.2) end
    pcall(function() cur.backdrop:Destroy() end)
    local f = cur.frame
    if f and f.Parent then tween(f, { Size = UDim2.new(0, cur.w, 0, 0) }, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In); Debris:AddItem(f, 0.2) end
end
function Popup.open(anchor, spec)
    if Popup.current and Popup.current.anchor == anchor then Popup.close(); return end
    Popup.close(); Tooltip.hide()
    local c = Theme.c
    local sc = fitScale.Scale
    local aAbs, aSize, oAbs = anchor.AbsolutePosition, anchor.AbsoluteSize, overlay.AbsolutePosition
    local aw, ah = aSize.X / sc, aSize.Y / sc
    local ax, ay = (aAbs.X - oAbs.X) / sc, (aAbs.Y - oAbs.Y) / sc
    local options = spec.options or {}
    local ROW_H, GAP, HEAD_H, PAD = 26, 2, 22, 6
    local rows = math.max(#options, 1)
    local visible = math.min(rows, 6)
    local listH = visible * (ROW_H + GAP) - GAP
    local totalH = PAD + HEAD_H + 5 + listH + PAD
    local totalW = math.max(aw, 156)
    local px = math.clamp(ax + aw - totalW, 8, winW - totalW - 8)
    local spaceBelow = winH - (ay + ah) - 12
    local spaceAbove = ay - 12
    local openUp = spaceBelow < totalH and spaceAbove > spaceBelow

    local backdrop = new("TextButton", { Name = "PopupBackdrop", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1, Parent = overlay })
    backdrop.MouseButton1Click:Connect(Popup.close)

    local pf = new("Frame", { Name = "Popup", BackgroundColor3 = c.bgCard, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5, Size = UDim2.new(0, totalW, 0, 0), Parent = overlay })
    corner(pf, 10); stroke(pf, c.accent, 1.2, 0.45)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 205, 212)), Parent = pf })
    if openUp then pf.AnchorPoint = Vector2.new(0, 1); pf.Position = UDim2.fromOffset(px, ay - 6)
    else pf.AnchorPoint = Vector2.new(0, 0); pf.Position = UDim2.fromOffset(px, ay + ah + 6) end

    newLabel(pf, spec.header or "Options", 10, FONT_STRONG, TEXT_DIM, { Size = UDim2.new(1, -20, 0, HEAD_H), Position = UDim2.new(0, 12, 0, PAD), ZIndex = 6 })
    new("Frame", { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, PAD + HEAD_H + 1), BackgroundColor3 = c.border, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 6, Parent = pf })

    local list = new("ScrollingFrame", { Size = UDim2.new(1, -12, 0, listH), Position = UDim2.new(0, 6, 0, PAD + HEAD_H + 5), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = c.accent, ScrollBarImageTransparency = 0.4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6, Parent = pf })
    new("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

    if #options == 0 then
        newLabel(list, spec.empty or "Nothing here", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1, 0, 0, ROW_H), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7 })
    else
        for i, name in ipairs(options) do
            local isSel = (name == spec.selected)
            local row = new("TextButton", { Size = UDim2.new(1, -4, 0, ROW_H), BackgroundColor3 = isSel and c.hover or c.bgMain, BackgroundTransparency = isSel and 0 or 0.4, Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 7, Parent = list })
            corner(row, 6); stroke(row, isSel and c.accent or c.border, 1, isSel and 0.2 or 0.5)
            newLabel(row, name, 11, isSel and FONT_STRONG or FONT_MAIN, isSel and c.accent or TEXT, { Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8 })
            if isSel then
                local dot = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = c.accent, BorderSizePixel = 0, ZIndex = 8, Parent = row })
                corner(dot, 3)
            end
            row.MouseButton1Click:Connect(function() Popup.close(); if spec.onPick then spec.onPick(name) end end)
        end
    end

    tween(pf, { Size = UDim2.new(0, totalW, 0, totalH) }, 0.26, Enum.EasingStyle.Back)
    if spec.arrow then tween(spec.arrow, { Rotation = 180 }, 0.22) end
    Popup.current = { frame = pf, backdrop = backdrop, anchor = anchor, arrow = spec.arrow, w = totalW }
end

local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = Theme.c.bgHeader, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 4, Parent = canvas })
Theme.bind(header, "BackgroundColor3", "bgHeader")
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(206, 206, 214)), Parent = header })

local headerLine = new("Frame", { Name = "HeaderGlow", Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, HEADER_H - 1), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 5, Parent = canvas })
Theme.bind(headerLine, "BackgroundColor3", "accent")
local headerLineGrad = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0), Parent = headerLine })
TweenService:Create(headerLineGrad, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1, 0) }):Play()

local hContent = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 5, Parent = header })
local logoImg = new("ImageLabel", { Name = "HeaderLogo", AnchorPoint = Vector2.new(0, 0), BackgroundTransparency = 1, Image = LOGO_ICON, ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 6, Parent = hContent })
logoImg.Size = UDim2.new(0, LOGO_CONFIG.width, 0, LOGO_CONFIG.height)
logoImg.Rotation = LOGO_CONFIG.rotation
logoImg.Position = UDim2.new(0, LOGO_CONFIG.posX, 0, LOGO_CONFIG.posY)

local BTN_SIZE, SEP_W = 30, 1
local BOX_W = BTN_SIZE * 3 + SEP_W * 2 + 6
local BOX_H = BTN_SIZE + 6

local pipe = new("Frame", { Size = UDim2.new(0, 3, 0, 24), Position = UDim2.new(0, 108, 0.5, -12), BackgroundColor3 = Color3.fromRGB(70, 70, 80), BorderSizePixel = 0, ZIndex = 6, Parent = hContent })
corner(pipe, 2)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.8) }), Parent = pipe })

local subtitleW = -(118 + BOX_W + 30)
newLabel(hContent, SUBTITLE_TEXT, 14, FONT_STRONG, TEXT, { Size = UDim2.new(1, subtitleW, 0, 18), Position = UDim2.new(0, 118, 0.5, -17), ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
local premiumLbl = newLabel(hContent, PREMIUM_TEXT, 11, FONT_STRONG, WHITE, { Size = UDim2.new(1, subtitleW, 0, 14), Position = UDim2.new(0, 118, 0.5, 3), ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
local premiumGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 186, 30)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 186, 30)) }), Offset = Vector2.new(-1, 0), Parent = premiumLbl })

local btnBox = new("Frame", { Size = UDim2.new(0, BOX_W, 0, BOX_H), Position = UDim2.new(1, -(BOX_W + 14), 0.5, -BOX_H / 2), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 8, Parent = hContent })
corner(btnBox, 9)
local btnBoxStroke = stroke(btnBox, Theme.c.border, 1, 0.1)
Theme.bind(btnBox, "BackgroundColor3", "bgMain"); Theme.bind(btnBoxStroke, "Color", "border")

local function makeIconBtn(image, order, size, tint, tip, hoverColor)
    size = size or 16
    local b = new("TextButton", { Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), Position = UDim2.new(0, 3 + (order - 1) * (BTN_SIZE + SEP_W), 0.5, -BTN_SIZE / 2), BackgroundColor3 = hoverColor or WHITE, BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 9, Parent = btnBox })
    corner(b, 7)
    local img = new("ImageLabel", { Size = UDim2.new(0, size, 0, size), Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2), BackgroundTransparency = 1, Image = image, ImageColor3 = tint or Color3.fromRGB(215, 215, 220), ZIndex = 10, Parent = b })
    b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = hoverColor and 0.7 or 0.88 }, 0.12); tween(img, { Size = UDim2.new(0, size + 3, 0, size + 3), Position = UDim2.new(0.5, -(size + 3) / 2, 0.5, -(size + 3) / 2) }, 0.15, Enum.EasingStyle.Back); if tip then Tooltip.show(tip, b) end end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }, 0.15); tween(img, { Size = UDim2.new(0, size, 0, size), Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2) }, 0.15); Tooltip.hide() end)
    return b, img
end

local discordBtn, discordIcon = makeIconBtn(DISCORD_ICON, 1, 22, DISCORD_TINT, "Discord")
local minimizeBtn = makeIconBtn(MIN_ICON, 2, 16, nil, "Minimize")
local closeBtnHeader = makeIconBtn(CLOSE_ICON, 3, 16, nil, "Close", C_ERROR)

for i = 1, 2 do
    local sep = new("Frame", { Size = UDim2.new(0, SEP_W, 0, BTN_SIZE - 8), Position = UDim2.new(0, 3 + i * BTN_SIZE + (i - 1) * SEP_W, 0.5, -(BTN_SIZE - 8) / 2), BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 9, Parent = btnBox })
    Theme.bind(sep, "BackgroundColor3", "border")
end

local dragCatcher = new("TextButton", { Size = UDim2.new(1, -(BOX_W + 28), 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 7, Parent = hContent })

local discordBusy = false
discordBtn.MouseButton1Click:Connect(function()
    if discordBusy then return end
    discordBusy = true
    pcall(function() setclipboard(DISCORD_URL) end)
    Tooltip.hide()
    local origSize, origPos = discordIcon.Size, discordIcon.Position
    tween(discordIcon, { Rotation = 360, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0.5, -14, 0.5, -14) }, 0.45, Enum.EasingStyle.Back)
    local check = new("ImageLabel", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0.5, -11, 0.5, -11), BackgroundTransparency = 1, Image = CHECK_ICON, ImageColor3 = C_SUCCESS, ImageTransparency = 1, Rotation = -90, ScaleType = Enum.ScaleType.Fit, ZIndex = 11, Parent = discordBtn })
    task.delay(0.25, function() if check.Parent then tween(check, { ImageTransparency = 0, Rotation = 0 }, 0.28, Enum.EasingStyle.Back) end end)
    task.delay(1.15, function() if check.Parent then tween(check, { ImageTransparency = 1 }, 0.2) end end)
    task.delay(1.4, function() if check.Parent then check:Destroy() end end)
    task.delay(1.2, function() if discordIcon.Parent then tween(discordIcon, { Rotation = 0, Size = origSize, Position = origPos }, 0.2) end end)
    notify("Discord", "Link copied!", 1.8, "success")
    task.delay(1.5, function() discordBusy = false end)
end)

local sidebar = new("Frame", { Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H), Position = UDim2.new(0, 0, 0, HEADER_H), BackgroundColor3 = Theme.c.bgHeader, BorderSizePixel = 0, ZIndex = 3, Parent = canvas })
Theme.bind(sidebar, "BackgroundColor3", "bgHeader")
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 200, 210)), Parent = sidebar })
local sideDivider = new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 4, Parent = sidebar })
Theme.bind(sideDivider, "BackgroundColor3", "border")

local TABS = {
    { name = "Main",     icon = "rbxassetid://7733960981" },
    { name = "Visuals",  icon = "rbxassetid://7743876754" },
    { name = "Players",  icon = "rbxassetid://7743876054" },
    { name = "Misc",     icon = "rbxassetid://7743878358" },
    { name = "Settings", icon = "rbxassetid://7734053495" },
}
local TAB_H, TAB_GAP, TAB_TOP = 38, 4, 12
local tabW = SIDEBAR_W - 18

local tabIndicator = new("Frame", { Name = "TabIndicator", Size = UDim2.fromOffset(tabW, TAB_H), Position = UDim2.fromOffset(8, TAB_TOP), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 1, Parent = sidebar })
corner(tabIndicator, 9)
local indStroke = stroke(tabIndicator, Theme.c.border, 1, 0.3)
Theme.bind(tabIndicator, "BackgroundColor3", "bgMain"); Theme.bind(indStroke, "Color", "accent")
local indBar = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0.55, 0), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 2, Parent = tabIndicator })
corner(indBar, 2); Theme.bind(indBar, "BackgroundColor3", "accent")

local profile = new("Frame", { Name = "Profile", Size = UDim2.new(0, tabW, 0, 48), Position = UDim2.new(0, 8, 1, -58), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 2, Parent = sidebar })
corner(profile, 10)
local profStroke = stroke(profile, Theme.c.border, 1, 0.25)
Theme.bind(profile, "BackgroundColor3", "bgMain"); Theme.bind(profStroke, "Color", "border")
local avatar = new("ImageLabel", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 8, 0.5, -16), BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 3, Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", LocalPlayer.UserId), Parent = profile })
corner(avatar, 16)
local avStroke = stroke(avatar, Theme.c.accent, 1.5, 0.2); Theme.bind(avStroke, "Color", "accent")
local onlineDot = new("Frame", { Size = UDim2.fromOffset(9, 9), Position = UDim2.new(0, 33, 0.5, 7), BackgroundColor3 = C_SUCCESS, BorderSizePixel = 0, ZIndex = 5, Parent = profile })
corner(onlineDot, 5)
local dotStroke = stroke(onlineDot, Theme.c.bgMain, 1.5, 0); Theme.bind(dotStroke, "Color", "bgMain")
newLabel(profile, LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name, 12, FONT_MAIN, TEXT, { Size = UDim2.new(1, -52, 0, 16), Position = UDim2.new(0, 48, 0.5, -16), TextTruncate = Enum.TextTruncate.AtEnd })
newLabel(profile, "@" .. LocalPlayer.Name, 10, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1, -52, 0, 14), Position = UDim2.new(0, 48, 0.5, 1), TextTruncate = Enum.TextTruncate.AtEnd })

local contentGroup = new("CanvasGroup", { Name = "Content", Size = UDim2.new(1, -SIDEBAR_W, 1, -HEADER_H), Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H), BackgroundTransparency = 1, GroupTransparency = 0, ZIndex = 2, Parent = canvas })
local pages = {}
local function makePage(tabName)
    local page = new("ScrollingFrame", { Name = tabName, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.c.accent, ScrollBarImageTransparency = 0.45, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, ZIndex = 3, Parent = contentGroup })
    Theme.bind(page, "ScrollBarImageColor3", "accent")
    new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16), Parent = page })
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    pages[tabName] = page
    return page
end
for _, tab in ipairs(TABS) do makePage(tab.name) end

local function cardBase(parent, height, order, clickable)
    local wrap = new("Frame", { Name = "Wrap", Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = order or 0, Parent = parent })
    wrap:SetAttribute("Entrance", true)
    local props = { Name = "Card", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrap }
    local card
    if clickable then props.AutoButtonColor = false; props.Text = ""; card = new("TextButton", props)
    else card = new("Frame", props) end
    corner(card, 10)
    local st = stroke(card, Theme.c.border, 1, 0)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(212, 212, 218)), Parent = card })
    local bar = new("Frame", { Name = "AccentBar", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 4, Parent = card })
    corner(bar, 2)
    return wrap, card, st, bar
end

local function setScrolling(page, enabled)
    if page and page:IsA("ScrollingFrame") then page.ScrollingEnabled = enabled end
end

local function addSectionHeader(parent, text, order)
    local wrap = new("Frame", { Name = "Section", Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
    local dot = new("Frame", { Size = UDim2.fromOffset(4, 12), Position = UDim2.new(0, 2, 0, 3), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, Parent = wrap })
    corner(dot, 2); Theme.bind(dot, "BackgroundColor3", "accent")
    newLabel(wrap, string.upper(text), 11, FONT_STRONG, TEXT_DIM, { Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 14, 0, 0) })
    local line = new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, Parent = wrap })
    Theme.bind(line, "BackgroundColor3", "accent")
    new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }), Parent = line })
    return wrap
end

local function addClickButton(parent, titleText, iconId, order, callback)
    local wrap, card, st, bar = cardBase(parent, CARD_H, order, true)
    local hover = false
    local title = newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 16, 0, 0) })
    local icon = new("ImageLabel", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -40, 0.5, -12), BackgroundTransparency = 1, Image = iconId, ImageColor3 = TEXT, ZIndex = 3, Parent = card })
    local function render(animate)
        local c = Theme.c; local d = animate and 0.18 or 0
        apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
        apply(st, { Color = hover and c.accent or c.border }, d)
        apply(title, { TextColor3 = hover and c.accent or TEXT }, d)
        apply(icon, { ImageColor3 = hover and c.accent or TEXT }, d)
        apply(bar, { Size = UDim2.new(0, 3, hover and 0.5 or 0, 0) }, d, Enum.EasingStyle.Back)
    end
    Theme.reg(card, function(_, a) render(a) end)
    card.MouseEnter:Connect(function() hover = true render(true) end)
    card.MouseLeave:Connect(function() hover = false render(true) end)
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end
    end)
    card.MouseButton1Click:Connect(function()
        tween(icon, { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -43, 0.5, -15), Rotation = 12 }, 0.1)
        task.delay(0.1, function() if icon.Parent then tween(icon, { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -40, 0.5, -12), Rotation = 0 }, 0.3, Enum.EasingStyle.Back) end end)
        if callback then callback(card) end
    end)
    return card
end

local function addToggle(parent, key, titleText, order, callback)
    local state = Options[key] == true
    local wrap, card, st, bar = cardBase(parent, CARD_H, order, true)
    local hover = false
    local title = newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 16, 0, 0) })
    local track = new("Frame", { Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -58, 0.5, -11), BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 3, Parent = card })
    corner(track, 11)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 205, 214)), Parent = track })
    local tStroke = stroke(track, Theme.c.border, 1, 0)
    local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = track })
    corner(knob, 8)
    local function render(animate)
        local c = Theme.c; local d = animate and 0.22 or 0
        apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
        apply(st, { Color = state and c.border:Lerp(c.accent, 0.45) or (hover and c.border:Lerp(c.accent, 0.3) or c.border) }, d)
        apply(title, { TextColor3 = state and c.accent or TEXT }, d)
        apply(track, { BackgroundColor3 = state and c.accent or c.trackOff }, d)
        apply(tStroke, { Color = state and c.glow or c.border }, d)
        apply(knob, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = state and WHITE or Color3.fromRGB(185, 185, 195) }, d, Enum.EasingStyle.Back)
        apply(bar, { Size = UDim2.new(0, 3, state and 0.55 or 0, 0) }, d, Enum.EasingStyle.Back)
    end
    Theme.reg(card, function(_, a) render(a) end)
    Registry[key] = function(v) state = v == true; setOption(key, state); render(true); if callback then pcall(callback, state) end end
    card.MouseEnter:Connect(function() hover = true render(true) end)
    card.MouseLeave:Connect(function() hover = false render(true) end)
    card.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end end)
    card.MouseButton1Click:Connect(function()
        state = not state
        setOption(key, state)
        tween(knob, { Size = UDim2.fromOffset(22, 16) }, 0.1)
        task.delay(0.1, function() if knob.Parent then tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.2, Enum.EasingStyle.Back) end end)
        render(true)
        if callback then callback(state) end
    end)
end

local function addSlider(parent, key, titleText, minV, maxV, order, callback)
    minV = minV or 0; maxV = maxV or 100
    local value = math.clamp(math.floor((tonumber(Options[key]) or minV) + 0.5), minV, maxV)
    local wrap, card, st, bar = cardBase(parent, 58, order, false)
    local hover, dragging, focused = false, false, false
    local title = newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 16, 0, 8) })
    local numBox = new("TextBox", { Size = UDim2.fromOffset(62, 24), Position = UDim2.new(1, -78, 0, 6), BackgroundColor3 = Theme.c.bgMain, Text = tostring(value), TextColor3 = Theme.c.accent, TextSize = 12, Font = FONT_STRONG, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 3, Parent = card })
    corner(numBox, 7)
    local nbStroke = stroke(numBox, Theme.c.border, 1, 0)
    local hit = new("TextButton", { Size = UDim2.new(1, -32, 0, 24), Position = UDim2.new(0, 16, 1, -30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = card })
    local track = new("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 4, Parent = hit })
    corner(track, 3)
    local ratio0 = (value - minV) / (maxV - minV)
    local fill = new("Frame", { Size = UDim2.new(ratio0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5, Parent = track })
    corner(fill, 3)
    local fillGrad = new("UIGradient", { Color = ColorSequence.new(Theme.c.accent, Theme.c.glow), Parent = fill })
    local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(ratio0, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6, Parent = track })
    corner(knob, 7)
    local kStroke = stroke(knob, Theme.c.accent, 2, 0)
    local function render(animate)
        local c = Theme.c; local d = animate and 0.18 or 0
        apply(card, { BackgroundColor3 = (hover or dragging) and c.hover or c.bgCard }, d)
        apply(st, { Color = (hover or dragging) and c.border:Lerp(c.accent, 0.4) or c.border }, d)
        apply(track, { BackgroundColor3 = c.trackOff }, d)
        apply(numBox, { BackgroundColor3 = c.bgMain, TextColor3 = c.accent }, d)
        apply(nbStroke, { Color = focused and c.accent or c.border }, d)
        apply(kStroke, { Color = c.accent }, d)
        apply(bar, { Size = UDim2.new(0, 3, dragging and 0.55 or 0, 0) }, d, Enum.EasingStyle.Back)
        apply(knob, { Size = dragging and UDim2.fromOffset(18, 18) or UDim2.fromOffset(14, 14) }, d, Enum.EasingStyle.Back)
        fillGrad.Color = ColorSequence.new(c.accent, c.glow)
    end
    Theme.reg(card, function(_, a) render(a) end)
    local function setValue(v, fromBox, silent)
        v = math.clamp(math.floor(v + 0.5), minV, maxV)
        local changed = v ~= value
        value = v
        setOption(key, value)
        local r = (value - minV) / (maxV - minV)
        local d = silent and 0 or 0.08
        apply(fill, { Size = UDim2.new(r, 0, 1, 0) }, d)
        apply(knob, { Position = UDim2.new(r, 0, 0.5, 0) }, d)
        if not fromBox then numBox.Text = tostring(value) end
        if not silent and changed and callback then callback(value) end
    end
    Registry[key] = function(v) setValue(tonumber(v) or minV, false, true) end
    local function fromX(x)
        local pos = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        setValue(minV + (maxV - minV) * pos, false)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setScrolling(parent, false); render(true); fromX(input.Position.X)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end
    end)
    bind(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false; setScrolling(parent, true); render(true)
        end
    end)
    numBox.Focused:Connect(function() focused = true render(true) end)
    numBox.FocusLost:Connect(function()
        focused = false; render(true)
        local n = tonumber(numBox.Text)
        if not n then numBox.Text = tostring(value) return end
        setValue(n, false)
    end)
    card.MouseEnter:Connect(function() hover = true render(true) end)
    card.MouseLeave:Connect(function() hover = false render(true) end)
end

local function addTextBox(parent, key, titleText, order, callback, placeholder)
    local initText = key and tostring(Options[key] or "") or ""
    local wrap, card, st, bar = cardBase(parent, CARD_H, order, false)
    local hover, focused = false, false
    newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -170, 1, 0), Position = UDim2.new(0, 16, 0, 0) })
    local box = new("TextBox", { Size = UDim2.fromOffset(142, 26), Position = UDim2.new(1, -156, 0.5, -13), BackgroundColor3 = Theme.c.bgMain, Text = initText, PlaceholderText = placeholder or "Digite...", PlaceholderColor3 = Color3.fromRGB(90, 90, 105), TextColor3 = Theme.c.accent, TextSize = 11, Font = FONT_STRONG, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = card })
    corner(box, 7)
    new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = box })
    local bStroke = stroke(box, Theme.c.border, 1, 0)
    local function render(animate)
        local c = Theme.c; local d = animate and 0.18 or 0
        apply(card, { BackgroundColor3 = (hover or focused) and c.hover or c.bgCard }, d)
        apply(st, { Color = focused and c.accent or (hover and c.border:Lerp(c.accent, 0.3) or c.border) }, d)
        apply(box, { BackgroundColor3 = c.bgMain, TextColor3 = c.accent }, d)
        apply(bStroke, { Color = focused and c.accent or c.border }, d)
    end
    Theme.reg(card, function(_, a) render(a) end)
    if key then Registry[key] = function(v) local s = tostring(v or ""); setOption(key, s); box.Text = s end end
    box.Focused:Connect(function() focused = true render(true) end)
    box.FocusLost:Connect(function() focused = false; render(true); if key then setOption(key, box.Text) end; if callback then callback(box.Text) end end)
    card.MouseEnter:Connect(function() hover = true render(true) end)
    card.MouseLeave:Connect(function() hover = false render(true) end)
    return box
end

local function addDropdown(parent, titleText, order, spec)
    local wrap, card, st, bar = cardBase(parent, CARD_H + 4, order, true)
    local hover = false
    newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -170, 1, 0), Position = UDim2.new(0, 16, 0, 0) })
    local box = new("Frame", { Size = UDim2.fromOffset(138, 28), Position = UDim2.new(1, -152, 0.5, -14), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 3, Parent = card })
    corner(box, 8)
    local boxStroke = stroke(box, Theme.c.border, 1, 0.1)
    local display = newLabel(box, "None", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 })
    local arrow = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -14, 0.5, 0), BackgroundTransparency = 1, Image = ARROW_ICON, ImageColor3 = TEXT_MUTED, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = box })
    local obj = {}
    local function render(animate)
        local c = Theme.c; local d = animate and 0.18 or 0
        local v = spec.get()
        local isNone = (v == nil or v == "" or v == "None")
        local open = Popup.current and Popup.current.anchor == box
        display.Text = isNone and "None" or v
        apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
        apply(st, { Color = (hover or open) and c.accent or c.border }, d)
        apply(display, { TextColor3 = isNone and TEXT_MUTED or c.accent }, d)
        apply(arrow, { ImageColor3 = (hover or open) and c.accent or TEXT_MUTED }, d)
        apply(box, { BackgroundColor3 = c.bgMain }, d)
        apply(boxStroke, { Color = open and c.accent or c.border }, d)
    end
    obj.refresh = function() render(true) end
    Theme.reg(card, function(_, a) render(a) end)
    card.MouseEnter:Connect(function() hover = true render(true) end)
    card.MouseLeave:Connect(function() hover = false render(true) end)
    card.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end end)
    card.MouseButton1Click:Connect(function()
        Popup.open(box, { header = spec.header, options = spec.getOptions(), selected = spec.get(), empty = spec.empty, arrow = arrow, onPick = function(name) spec.set(name); render(true) end })
        task.delay(0.05, function() render(true) end)
    end)
    return obj
end

local function addButtonRow(parent, order, defs)
    local wrap = new("Frame", { Name = "Wrap", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
    wrap:SetAttribute("Entrance", true)
    local row = new("Frame", { Name = "Card", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = wrap })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
    local n = #defs
    local buttons = {}
    for i, def in ipairs(defs) do
        local btn = new("TextButton", { Size = UDim2.new(1 / n, -(8 * (n - 1) / n), 1, 0), BackgroundColor3 = Theme.c.bgCard, Text = def.text, TextColor3 = TEXT, Font = FONT_MAIN, TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, LayoutOrder = i, Parent = row })
        corner(btn, 9)
        local bs = stroke(btn, Theme.c.border, 1, 0.2)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(212, 212, 218)), Parent = btn })
        local hover = false
        local function render(animate)
            local c = Theme.c; local d = animate and 0.15 or 0
            local hc = def.hoverColor or c.accent
            apply(btn, { BackgroundColor3 = hover and c.hover or c.bgCard, TextColor3 = hover and hc or TEXT }, d)
            apply(bs, { Color = hover and hc or c.border, Transparency = hover and 0 or 0.2 }, d)
        end
        Theme.reg(btn, function(_, a) render(a) end)
        btn.MouseEnter:Connect(function() hover = true render(true) end)
        btn.MouseLeave:Connect(function() hover = false render(true) end)
        btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(btn, input) end end)
        btn.MouseButton1Click:Connect(function() if def.callback then def.callback(btn) end end)
        buttons[i] = btn
    end
    return buttons
end

local function addColorPicker(parent, key, titleText, order)
    local EXPANDED_H = CARD_H + 168
    local wrap, card, st, bar = cardBase(parent, CARD_H, order, false)
    local hover = false
    newLabel(card, titleText, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -150, 0, CARD_H), Position = UDim2.new(0, 16, 0, 0) })
    local hexLbl = newLabel(card, toHex(Options[key] or WHITE), 11, FONT_CODE, TEXT_MUTED, { Size = UDim2.fromOffset(70, CARD_H), Position = UDim2.new(1, -128, 0, 0), TextXAlignment = Enum.TextXAlignment.Right })
    local colorSq = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -46, 0, 6), BackgroundColor3 = Options[key] or WHITE, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6, Parent = card })
    corner(colorSq, 8)
    local sqStroke = stroke(colorSq, Theme.c.border, 1.5, 0)
    local rowHit = new("TextButton", { Size = UDim2.new(1, 0, 0, CARD_H), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = card })
    local content = new("Frame", { Size = UDim2.new(1, 0, 0, EXPANDED_H - CARD_H), Position = UDim2.new(0, 0, 0, CARD_H), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
    new("Frame", { Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 0), BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = content })
    local preview = new("Frame", { Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 16, 0, 14), BackgroundColor3 = Options[key] or WHITE, BorderSizePixel = 0, ZIndex = 3, Parent = content })
    corner(preview, 10); stroke(preview, Theme.c.border, 1.5, 0)
    local previewHex = newLabel(content, toHex(Options[key] or WHITE), 12, FONT_CODE, TEXT, { Size = UDim2.fromOffset(100, 18), Position = UDim2.new(0, 16, 0, 84) })
    newLabel(content, "R G B", 9, FONT_MAIN, TEXT_MUTED, { Size = UDim2.fromOffset(100, 12), Position = UDim2.new(0, 16, 0, 102) })
    local SV = 118
    local sv = new("Frame", { Size = UDim2.fromOffset(SV, SV), Position = UDim2.new(1, -(SV + 16), 0, 14), BackgroundColor3 = Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = content })
    corner(sv, 8); stroke(sv, Theme.c.border, 1, 0.2)
    local whiteLayer = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = sv })
    corner(whiteLayer, 8); new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = whiteLayer })
    local blackLayer = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 5, Parent = sv })
    corner(blackLayer, 8); new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = blackLayer })
    local svHit = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 7, Parent = sv })
    local svCursor = new("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8, Parent = sv })
    corner(svCursor, 8); stroke(svCursor, WHITE, 2, 0)
    local svDot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 8, Parent = svCursor })
    corner(svDot, 2)
    local hueWrap = new("Frame", { Size = UDim2.new(1, -32, 0, 18), Position = UDim2.new(0, 16, 0, 14 + SV + 12), BackgroundTransparency = 1, ZIndex = 3, Parent = content })
    local hueTrack = new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3, Parent = hueWrap })
    corner(hueTrack, 6)
    new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }), Parent = hueTrack })
    local hueHit = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = hueWrap })
    local hueCursor = new("Frame", { Size = UDim2.fromOffset(16, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, ZIndex = 6, Parent = hueWrap })
    corner(hueCursor, 6); stroke(hueCursor, WHITE, 2.5, 0)
    local h0, s0, v0 = rgbToHsv(Options[key] or WHITE)
    local picker = { hue = h0, sat = s0, val = v0, svDrag = false, hueDrag = false, open = false }
    local function placeSV() svCursor.Position = UDim2.new(picker.sat, 0, 1 - picker.val, 0) end
    local function placeHue() hueCursor.Position = UDim2.new(picker.hue / 360, 0, 0.5, 0); hueCursor.BackgroundColor3 = hsvToRgb(picker.hue, 1, 1) end
    local function commit()
        local c = hsvToRgb(picker.hue, picker.sat, picker.val)
        genv.BabisESPColor = c
        setOption(key, c)
        preview.BackgroundColor3 = c; colorSq.BackgroundColor3 = c
        local hx = toHex(c); hexLbl.Text = hx; previewHex.Text = hx
    end
    placeSV(); placeHue()
    sv.BackgroundColor3 = hsvToRgb(picker.hue, 1, 1)
    Registry[key] = function(newColor)
        if typeof(newColor) ~= "Color3" then return end
        local h, s, v = rgbToHsv(newColor)
        picker.hue, picker.sat, picker.val = h, s, v
        placeSV(); placeHue(); sv.BackgroundColor3 = hsvToRgb(h, 1, 1); commit()
    end
    local function updateSV(mx, my)
        local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
        if as.X <= 0 or as.Y <= 0 then return end
        picker.sat = math.clamp((mx - ap.X) / as.X, 0, 1)
        picker.val = 1 - math.clamp((my - ap.Y) / as.Y, 0, 1)
        placeSV(); commit()
    end
    local function updateHue(mx)
        local ap, as = hueWrap.AbsolutePosition, hueWrap.AbsoluteSize
        if as.X <= 0 then return end
        picker.hue = math.clamp((mx - ap.X) / as.X, 0, 1) * 359.99
        placeHue(); sv.BackgroundColor3 = hsvToRgb(picker.hue, 1, 1); commit()
    end
    svHit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then picker.svDrag = true; setScrolling(parent, false); updateSV(input.Position.X, input.Position.Y) end
    end)
    hueHit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then picker.hueDrag = true; setScrolling(parent, false); updateHue(input.Position.X) end
    end)
    bind(UserInputService.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if picker.svDrag then updateSV(input.Position.X, input.Position.Y)
        elseif picker.hueDrag then updateHue(input.Position.X) end
    end)
    bind(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if picker.svDrag or picker.hueDrag then setScrolling(parent, true) end
            picker.svDrag, picker.hueDrag = false, false
        end
    end)
    local function render(animate)
        local c = Theme.c; local d = animate and 0.2 or 0
        apply(card, { BackgroundColor3 = (hover or picker.open) and c.hover or c.bgCard }, d)
        apply(st, { Color = picker.open and c.accent or (hover and c.border:Lerp(c.accent, 0.3) or c.border) }, d)
        apply(sqStroke, { Color = picker.open and c.accent or c.border }, d)
    end
    Theme.reg(card, function(_, a) render(a) end)
    local function setOpen(open)
        picker.open = open
        tween(wrap, { Size = UDim2.new(1, 0, 0, open and EXPANDED_H or CARD_H) }, 0.34, Enum.EasingStyle.Quint)
        render(true)
    end
    colorSq.Activated:Connect(function() setOpen(not picker.open) end)
    rowHit.Activated:Connect(function() setOpen(not picker.open) end)
    rowHit.MouseEnter:Connect(function() hover = true render(true) end)
    rowHit.MouseLeave:Connect(function() hover = false render(true) end)
end

-- ===== GAME LOGIC — wrapped in closure to avoid 200-local limit =====
local Game = (function()

local Overlay = { activeKill = nil, activeClimb = nil }

local function showKillOverlay(duration)
    duration = duration or 2.0
    if Overlay.activeKill and Overlay.activeKill.Parent then Overlay.activeKill:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "BabisKillOverlay"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999999; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = uiParent; Overlay.activeKill = sg
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Parent = sg
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.Text = "TRYING TO KILL HULK"
    lbl.TextColor3 = Color3.fromRGB(255, 40, 40); lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 52; lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.fromRGB(120, 0, 0)
    lbl.TextTransparency = 1; lbl.Size = UDim2.new(0, 0, 0, 90)
    lbl.Position = UDim2.new(0.5, 0, 0.5, -45); lbl.AnchorPoint = Vector2.new(0.5, 0.5); lbl.Parent = bg
    TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 90), TextTransparency = 0 }):Play()
    task.delay(math.max(duration - 0.6, 0.1), function()
        TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
    end)
    task.delay(duration, function() if sg and sg.Parent then sg:Destroy() end; if Overlay.activeKill == sg then Overlay.activeKill = nil end end)
end

local function showClimbOverlay(duration)
    duration = duration or 1.2
    if Overlay.activeClimb and Overlay.activeClimb.Parent then Overlay.activeClimb:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "BabisClimbOverlay"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999997; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = uiParent; Overlay.activeClimb = sg
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Parent = sg
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.Text = "CLIMBING"
    lbl.TextColor3 = Color3.fromRGB(90, 165, 255); lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 44; lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.fromRGB(20, 50, 120)
    lbl.TextTransparency = 1; lbl.Size = UDim2.new(1, 0, 0, 80)
    lbl.Position = UDim2.new(0.5, 0, 0.5, -40); lbl.AnchorPoint = Vector2.new(0.5, 0.5); lbl.Parent = bg
    TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    task.delay(math.max(duration - 0.35, 0.1), function()
        TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
    end)
    task.delay(duration, function() if sg and sg.Parent then sg:Destroy() end; if Overlay.activeClimb == sg then Overlay.activeClimb = nil end end)
end

local InfiniteStamina = {
    enabled = false, runTrack = nil, crawlTouchUntil = 0, crawlBtnRef = nil,
    connBegin = nil, connEnd = nil,
    sprintBtnRef = nil, sprintWasVisible = true, sprintConn = nil,
    hulkSprintBtnRef = nil, hulkSprintWasVisible = true, hulkSprintConn = nil,
    RUN_ID = "rbxassetid://93208526042306", TARGET_SPEED = 35, CRAWL_SPEED = 12,
    CRAWL_GUI = "SurvivorMobileControls", CRAWL_BTN = "CrawlButton", SPRINT_BTN = "SprintButton",
    HULK_GUI = "HulkUI_TouchAbilityActivation", HULK_CLUSTER = "ActionCluster", HULK_SPRINT = "Sprint",
}
do
    local function getChar() return LocalPlayer.Character end
    local function getHum() local ch = getChar(); return ch and ch:FindFirstChildOfClass("Humanoid") end
    local function getAnimator() local hum = getHum(); return hum and (hum:FindFirstChildOfClass("Animator") or hum) end

    local function applySprintVisibility()
        local gui = PlayerGui:FindFirstChild(InfiniteStamina.CRAWL_GUI); if not gui then return end
        local btn = gui:FindFirstChild(InfiniteStamina.SPRINT_BTN); if not btn then return end
        if InfiniteStamina.sprintBtnRef ~= btn then
            InfiniteStamina.sprintBtnRef = btn; InfiniteStamina.sprintWasVisible = btn.Visible
            if InfiniteStamina.sprintConn then pcall(function() InfiniteStamina.sprintConn:Disconnect() end) end
            InfiniteStamina.sprintConn = btn:GetPropertyChangedSignal("Visible"):Connect(function()
                if InfiniteStamina.enabled and btn.Visible then btn.Visible = false end
            end)
        end
        if InfiniteStamina.enabled then btn.Visible = false
        else btn.Visible = InfiniteStamina.sprintWasVisible end
    end

    local function applyHulkSprintVisibility()
        local gui = PlayerGui:FindFirstChild(InfiniteStamina.HULK_GUI); if not gui then return end
        local cluster = gui:FindFirstChild(InfiniteStamina.HULK_CLUSTER); if not cluster then return end
        local btn = cluster:FindFirstChild(InfiniteStamina.HULK_SPRINT); if not btn then return end
        if InfiniteStamina.hulkSprintBtnRef ~= btn then
            InfiniteStamina.hulkSprintBtnRef = btn; InfiniteStamina.hulkSprintWasVisible = btn.Visible
            if InfiniteStamina.hulkSprintConn then pcall(function() InfiniteStamina.hulkSprintConn:Disconnect() end) end
            InfiniteStamina.hulkSprintConn = btn:GetPropertyChangedSignal("Visible"):Connect(function()
                if InfiniteStamina.enabled and btn.Visible then btn.Visible = false end
            end)
        end
        if InfiniteStamina.enabled then btn.Visible = false
        else btn.Visible = InfiniteStamina.hulkSprintWasVisible end
    end

    local function tryBindCrawlButton()
        local gui = PlayerGui:FindFirstChild(InfiniteStamina.CRAWL_GUI); if not gui then return false end
        local btn = gui:FindFirstChild(InfiniteStamina.CRAWL_BTN); if not btn then return false end
        if InfiniteStamina.crawlBtnRef == btn then return true end
        if InfiniteStamina.connBegin then InfiniteStamina.connBegin:Disconnect() end
        if InfiniteStamina.connEnd then InfiniteStamina.connEnd:Disconnect() end
        InfiniteStamina.crawlBtnRef = btn
        InfiniteStamina.connBegin = btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                InfiniteStamina.crawlTouchUntil = tick() + 0.5
            end
        end)
        InfiniteStamina.connEnd = btn.InputEnded:Connect(function() end)
        return true
    end
    task.spawn(function() while not tryBindCrawlButton() do task.wait(1) end end)
    PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == InfiniteStamina.CRAWL_GUI then task.wait(0.5); tryBindCrawlButton(); applySprintVisibility()
        elseif child.Name == InfiniteStamina.HULK_GUI then task.wait(0.5); applyHulkSprintVisibility() end
    end)
    task.spawn(function() while alive do task.wait(0.5); applyHulkSprintVisibility() end end)

    local function ensureRunTrack()
        if InfiniteStamina.runTrack then return end
        local animator = getAnimator(); if not animator then return end
        local anim = Instance.new("Animation"); anim.AnimationId = InfiniteStamina.RUN_ID
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not track then return end
        track.Priority = Enum.AnimationPriority.Action4; track.Looped = true
        InfiniteStamina.runTrack = track
    end
    local function stopRun(fade)
        if InfiniteStamina.runTrack and InfiniteStamina.runTrack.IsPlaying then
            pcall(function() InfiniteStamina.runTrack:Stop(fade or 0.05) end)
        end
    end
    local function playRun(fade)
        if InfiniteStamina.runTrack and not InfiniteStamina.runTrack.IsPlaying then
            pcall(function() InfiniteStamina.runTrack:Play(fade or 0.1) end)
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        if not InfiniteStamina.enabled then stopRun(0.05); return end
        local ch = getChar(); local hum = getHum()
        if not ch or not hum then stopRun(0.05); return end
        ensureRunTrack()
        if hum.MoveDirection.Magnitude <= 0.1 then stopRun(0.05); return end
        local extra = math.max(0, InfiniteStamina.TARGET_SPEED - hum.WalkSpeed)
        if extra > 0 then pcall(function() ch:TranslateBy(hum.MoveDirection * (extra * dt)) end) end
        if hum.WalkSpeed > InfiniteStamina.CRAWL_SPEED and tick() < InfiniteStamina.crawlTouchUntil then
            InfiniteStamina.crawlTouchUntil = 0
        end
        local byTouch = tick() < InfiniteStamina.crawlTouchUntil
        local bySpeed = hum.WalkSpeed > 0 and hum.WalkSpeed <= InfiniteStamina.CRAWL_SPEED
        if byTouch or bySpeed then stopRun(0.05); return end
        playRun(0.1)
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        InfiniteStamina.runTrack = nil; InfiniteStamina.crawlTouchUntil = 0
        task.wait(0.5); tryBindCrawlButton(); applySprintVisibility(); applyHulkSprintVisibility()
    end)

    function InfiniteStamina.enable() InfiniteStamina.enabled = true; applySprintVisibility(); applyHulkSprintVisibility() end
    function InfiniteStamina.disable() InfiniteStamina.enabled = false; stopRun(0.05); InfiniteStamina.crawlTouchUntil = 0; applySprintVisibility(); applyHulkSprintVisibility() end
end

local PlayerState = { jumpEnabled = false, speedPower = false, jumpPower = 50, tpSpeed = 3 }
local function getHumanoid() local ch = LocalPlayer.Character; return ch and ch:FindFirstChildOfClass("Humanoid") end
local function applyPlayerState()
    local hum = getHumanoid(); if not hum then return end
    if PlayerState.jumpEnabled then
        pcall(function() hum.JumpPower = PlayerState.jumpPower end)
        pcall(function() hum.UseJumpPower = true end)
    end
end
RunService.Heartbeat:Connect(function()
    if not PlayerState.speedPower then return end
    local ch = LocalPlayer.Character; if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if hum.MoveDirection.Magnitude > 0 then pcall(function() ch:TranslateBy(hum.MoveDirection * PlayerState.tpSpeed) end) end
end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); applyPlayerState() end)

local AntiRagdoll = { enabled = false, forceWalkSpeed = 16, forceState = true }
local AR_MOTOR_NAMES = { RootJoint=true, Neck=true, ["Left Shoulder"]=true, ["Right Shoulder"]=true, ["Left Hip"]=true, ["Right Hip"]=true, Waist=true }
local function arFix()
    if not AntiRagdoll.enabled then return end
    local ch = LocalPlayer.Character; if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if ch:GetAttribute("Ragdolled") == true then pcall(function() ch:SetAttribute("Ragdolled", false) end) end
    if hum.PlatformStand then pcall(function() hum.PlatformStand = false end) end
    if hum.WalkSpeed < 1 then pcall(function() hum.WalkSpeed = AntiRagdoll.forceWalkSpeed end) end
    for _, d in ipairs(ch:GetDescendants()) do
        if d:IsA("Motor6D") and d.Enabled == false and AR_MOTOR_NAMES[d.Name] then pcall(function() d.Enabled = true end) end
        if d:IsA("BallSocketConstraint") and d.Name == "__HulkRagdollSocket" and d.Enabled then pcall(function() d.Enabled = false end) end
    end
    if AntiRagdoll.forceState then
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.PlatformStanding or st == Enum.HumanoidStateType.Physics
           or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
end
pcall(function() RunService:BindToRenderStep("BabisAntiRagdoll", Enum.RenderPriority.Character.Value + 1, arFix) end)
RunService.Heartbeat:Connect(arFix)
function AntiRagdoll.enable() AntiRagdoll.enabled = true end
function AntiRagdoll.disable() AntiRagdoll.enabled = false end

local PlayerESP = {
    flags = { hulk=false, hulkbuster=false, survivor=false, weapon=false, abilityHighlight=false },
    colors = { Hulk=Color3.fromRGB(60,220,100), Hulkbuster=Color3.fromRGB(255,200,40),
        Survivor=Color3.fromRGB(60,130,255), SurvivorAbility=Color3.fromRGB(255,200,40),
        Weapon=Color3.fromRGB(255,60,180), Ragdoll=Color3.fromRGB(255,150,50) },
    espByPlayer = {}, loop = nil,
}
local function peGetRole(ch)
    if not ch then return nil end
    if ch:GetAttribute("IsHulk") then return "Hulk" end
    if ch:GetAttribute("HulkbusterActive") then return "Hulkbuster" end
    return "Survivor"
end
local function peIsRagdolled(ch)
    local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    if hum.PlatformStand then return true end
    local st = hum:GetState()
    if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll then return true end
    for _, a in ipairs({"IsRagdolled","Ragdolled","Ragdoll","IsDowned","Downed"}) do
        if ch:GetAttribute(a) == true then return true end
    end
    return false
end
local function peHasAbility(p) return p:GetAttribute("OwnsHulkbuster") == true end
local function peClear(p)
    local e = PlayerESP.espByPlayer[p]; if not e then return end
    if e.highlight then pcall(function() e.highlight:Destroy() end) end
    if e.billboard then pcall(function() e.billboard:Destroy() end) end
    if e.weaponHL then pcall(function() e.weaponHL:Destroy() end) end
    PlayerESP.espByPlayer[p] = nil
end
local function peClearAll() for p in pairs(PlayerESP.espByPlayer) do peClear(p) end end
local function peApply(p)
    if p == LocalPlayer then return end
    local ch = p.Character; if not ch then peClear(p); return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then peClear(p); return end
    local role = peGetRole(ch); local roleFlag = false
    if role == "Hulk" and PlayerESP.flags.hulk then roleFlag = true end
    if role == "Hulkbuster" and PlayerESP.flags.hulkbuster then roleFlag = true end
    if role == "Survivor" and PlayerESP.flags.survivor then roleFlag = true end
    local weaponFlag = PlayerESP.flags.weapon
    if not roleFlag and not weaponFlag then peClear(p); return end
    local ragdolled = peIsRagdolled(ch)
    local color = PlayerESP.colors[role] or PlayerESP.colors.Survivor
    if role == "Survivor" and PlayerESP.flags.abilityHighlight and peHasAbility(p) then color = PlayerESP.colors.SurvivorAbility end
    if ragdolled then color = PlayerESP.colors.Ragdoll end
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
    if not hrp then return end
    local e = PlayerESP.espByPlayer[p]
    if roleFlag then
        if not e or not e.highlight or e.highlight.Parent ~= ch then
            if e then peClear(p) end
            e = {}
            local h = Instance.new("Highlight")
            h.FillColor=color; h.FillTransparency=0.55; h.OutlineColor=color; h.OutlineTransparency=0
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=ch
            e.highlight = h
            local bb = Instance.new("BillboardGui")
            bb.Size=UDim2.new(0,200,0,44); bb.StudsOffset=Vector3.new(0,3.2,0); bb.AlwaysOnTop=true; bb.Parent=hrp
            local lbl = Instance.new("TextLabel")
            lbl.Name="Lbl"; lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.TextStrokeTransparency=0
            lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.Parent=bb
            e.billboard = bb; PlayerESP.espByPlayer[p] = e
        end
        if e.highlight and e.highlight.FillColor ~= color then
            e.highlight.FillColor=color; e.highlight.OutlineColor=color
        end
        local lbl = e.billboard and e.billboard:FindFirstChild("Lbl")
        if lbl then
            local myHrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head"))
            local dTxt = myHrp and string.format(" [%d]", math.floor((hrp.Position - myHrp.Position).Magnitude)) or ""
            local tag = ""
            if role == "Hulk" then tag=" HULK"
            elseif role == "Hulkbuster" then tag=" HULKBUSTER"
            elseif role == "Survivor" and PlayerESP.flags.abilityHighlight and peHasAbility(p) then tag=" HB-ABILITY"
            elseif ragdolled then tag=" (DOWN)" end
            lbl.Text = p.Name .. tag .. dTxt; lbl.TextColor3 = color
        end
    else
        if e then
            if e.highlight then e.highlight:Destroy(); e.highlight=nil end
            if e.billboard then e.billboard:Destroy(); e.billboard=nil end
            if not e.weaponHL then PlayerESP.espByPlayer[p]=nil end
        end
    end
    if weaponFlag then
        if not e then e = {}; PlayerESP.espByPlayer[p]=e end
        local tool = ch:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                if not e.weaponHL or e.weaponHL.Parent ~= handle then
                    if e.weaponHL then e.weaponHL:Destroy() end
                    local whl = Instance.new("Highlight")
                    whl.FillColor=PlayerESP.colors.Weapon; whl.FillTransparency=0.3
                    whl.OutlineColor=PlayerESP.colors.Weapon; whl.OutlineTransparency=0
                    whl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; whl.Parent=handle
                    e.weaponHL = whl
                end
            end
        elseif e.weaponHL then
            e.weaponHL:Destroy(); e.weaponHL=nil
        end
    elseif e and e.weaponHL then
        e.weaponHL:Destroy(); e.weaponHL=nil
    end
end
local function peRefresh()
    if not PlayerESP.loop then
        PlayerESP.loop = task.spawn(function()
            while alive do
                task.wait(0.15)
                local any = PlayerESP.flags.hulk or PlayerESP.flags.hulkbuster or PlayerESP.flags.survivor or PlayerESP.flags.weapon
                if not any then peClearAll() else
                    local aliveSet = {}
                    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then peApply(p); aliveSet[p]=true end end
                    for p in pairs(PlayerESP.espByPlayer) do if not aliveSet[p] then peClear(p) end end
                end
            end
        end)
    end
end
function PlayerESP.setFlag(k, v) PlayerESP.flags[k] = v; peRefresh() end

local ChanceESP = {
    enabled = false, esp = {}, loop = nil,
    colors = { low=Color3.fromRGB(60,220,100), mid=Color3.fromRGB(255,220,60),
        high=Color3.fromRGB(255,140,40), top=Color3.fromRGB(255,60,60),
        hulk=Color3.fromRGB(80,255,130), blocked=Color3.fromRGB(120,120,130) },
    offsetY = 6.8, sizeX = 150, sizeY = 40,
}
local function chanceGetColor(chance, state, isHulk)
    if isHulk then return ChanceESP.colors.hulk end
    if state and tostring(state):find("BLOCKED") then return ChanceESP.colors.blocked end
    if chance >= 15 then return ChanceESP.colors.top end
    if chance >= 12 then return ChanceESP.colors.high end
    if chance >= 8 then return ChanceESP.colors.mid end
    return ChanceESP.colors.low
end
local function chanceIsHulkNow(ch)
    if not ch then return false end
    return ch:GetAttribute("IsHulk") == true or ch:GetAttribute("Transforming") == true
end
local function chanceClear(p)
    local e = ChanceESP.esp[p]; if not e then return end
    if e.bb then pcall(function() e.bb:Destroy() end) end
    ChanceESP.esp[p] = nil
end
local function chanceClearAll() for p in pairs(ChanceESP.esp) do chanceClear(p) end end
local function chanceApply(p)
    if p == LocalPlayer then return end
    local ch = p.Character; if not ch then chanceClear(p); return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then chanceClear(p); return end
    local chance = p:GetAttribute("HulkChancePercent") or 0
    local pity = p:GetAttribute("HulkPityRounds") or 0
    local hardPity = p:GetAttribute("HulkHardPityRounds") or 8
    local state = p:GetAttribute("HulkChanceState") or "NORMAL"
    local isH = chanceIsHulkNow(ch)
    local color = chanceGetColor(chance, state, isH)
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head") or ch:FindFirstChild("Torso")
    if not hrp then chanceClear(p); return end
    local e = ChanceESP.esp[p]
    if not e or not e.bb or e.bb.Parent ~= hrp then
        if e then chanceClear(p) end
        e = {}
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, ChanceESP.sizeX, 0, ChanceESP.sizeY)
        bb.StudsOffset = Vector3.new(0, ChanceESP.offsetY, 0)
        bb.AlwaysOnTop = true; bb.Parent = hrp
        e.bb = bb
        local chanceLbl = Instance.new("TextLabel")
        chanceLbl.Size = UDim2.new(1, 0, 0, 22); chanceLbl.BackgroundTransparency = 1
        chanceLbl.Text = "0.00%"; chanceLbl.TextColor3 = color; chanceLbl.Font = Enum.Font.GothamBlack
        chanceLbl.TextSize = 17; chanceLbl.TextStrokeTransparency = 0; chanceLbl.TextStrokeColor3 = Color3.new(0,0,0)
        chanceLbl.TextXAlignment = Enum.TextXAlignment.Center; chanceLbl.Parent = bb
        e.chanceLbl = chanceLbl
        local pityLbl = Instance.new("TextLabel")
        pityLbl.Size = UDim2.new(1, 0, 0, 16); pityLbl.Position = UDim2.new(0, 0, 0, 22)
        pityLbl.BackgroundTransparency = 1; pityLbl.Text = "pity 0/8"
        pityLbl.TextColor3 = color; pityLbl.Font = Enum.Font.GothamBold
        pityLbl.TextSize = 13; pityLbl.TextStrokeTransparency = 0; pityLbl.TextStrokeColor3 = Color3.new(0,0,0)
        pityLbl.TextXAlignment = Enum.TextXAlignment.Center; pityLbl.Parent = bb
        e.pityLbl = pityLbl; ChanceESP.esp[p] = e
    end
    if e.chanceLbl.TextColor3 ~= color then e.chanceLbl.TextColor3 = color; e.pityLbl.TextColor3 = color end
    if isH then e.chanceLbl.Text = "HULK NOW"
    elseif tostring(state):find("BLOCKED") then e.chanceLbl.Text = "BLOCKED"
    else e.chanceLbl.Text = string.format("%.2f%%", chance) end
    if state == "HARD_PITY" then e.pityLbl.Text = "GUARANTEED next!"
    else e.pityLbl.Text = string.format("pity %d/%d", pity, hardPity) end
end
local function chanceTick()
    local aliveSet = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then chanceApply(p); aliveSet[p]=true end end
    for p in pairs(ChanceESP.esp) do if not aliveSet[p] then chanceClear(p) end end
end
function ChanceESP.enable()
    if ChanceESP.enabled then return end
    ChanceESP.enabled = true; chanceTick()
    ChanceESP.loop = task.spawn(function() while ChanceESP.enabled do task.wait(0.4); if ChanceESP.enabled then pcall(chanceTick) end end end)
end
function ChanceESP.disable() ChanceESP.enabled = false; chanceClearAll() end

local EspVents = { enabled=false, color=Color3.fromRGB(180,80,255), fillTrans=0.4, outlineTrans=0, scanInterval=3, patterns={"vent","nightlight"}, esp={}, parent=nil, loop=nil }
local function ventNameMatches(name)
    local n = name:lower()
    for _, p in ipairs(EspVents.patterns) do if n:match(p) then return true end end
    return false
end
local function ventFindParent()
    local fac = Workspace:FindFirstChild("HulkFacility440x340")
    if not fac then
        for _, c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") and c.Name:lower():match("hulkfacility") then fac = c; break end
        end
    end
    if not fac then return nil end
    local trim = fac:FindFirstChild("Trim"); if not trim then return nil end
    return trim:FindFirstChild("VentFrames")
end
local function ventGetMainPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) end
    return nil
end
local function ventClearESP(inst)
    local e = EspVents.esp[inst]; if not e then return end
    if e.hl then pcall(function() e.hl:Destroy() end) end
    EspVents.esp[inst] = nil
end
local function ventApply(inst)
    if not inst or not inst.Parent then return end
    if not ventNameMatches(inst.Name) then return end
    local main = ventGetMainPart(inst); if not main then return end
    local parentForHL = inst:IsA("Model") and inst or main
    local e = EspVents.esp[inst]
    if not e or (e.hl and e.hl.Parent ~= parentForHL) then
        if e then ventClearESP(inst) end
        e = {}
        local hl = Instance.new("Highlight")
        hl.Name="BabisVentHL"; hl.FillColor=EspVents.color; hl.FillTransparency=EspVents.fillTrans
        hl.OutlineColor=EspVents.color; hl.OutlineTransparency=EspVents.outlineTrans
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=parentForHL
        e.hl = hl; EspVents.esp[inst] = e
    end
end
local function ventRescan()
    if not EspVents.parent or not EspVents.parent.Parent then EspVents.parent = ventFindParent() end
    if not EspVents.parent then return end
    for inst in pairs(EspVents.esp) do if not inst.Parent then ventClearESP(inst) end end
    for _, child in ipairs(EspVents.parent:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("Model") then ventApply(child) end
    end
end
local function ventClearAll() for inst in pairs(EspVents.esp) do ventClearESP(inst) end end
function EspVents.enable()
    EspVents.enabled = true
    task.spawn(function() task.wait(0.1); ventRescan() end)
    if not EspVents.loop then
        EspVents.loop = task.spawn(function() while alive do task.wait(EspVents.scanInterval); if EspVents.enabled then pcall(ventRescan) end end end)
    end
end
function EspVents.disable() EspVents.enabled = false; ventClearAll() end

local EspCabinet = { enabled=false, color=Color3.fromRGB(210,170,120), fillTrans=0.35, outlineTrans=0, scanInterval=3, esp={}, loop=nil }
local function cabinetFindAll()
    local found, seen = {}, {}
    local furn = Workspace:FindFirstChild("Furniture")
    if furn then
        for _, d in ipairs(furn:GetDescendants()) do
            if d:IsA("Model") and d.Name == "Closet" and not seen[d] then seen[d]=true; table.insert(found, d) end
        end
    end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "Closet" and not seen[d] then seen[d]=true; table.insert(found, d) end
    end
    return found
end
local function cabinetClearESP(inst)
    local hl = EspCabinet.esp[inst]; if hl then pcall(function() hl:Destroy() end) end
    EspCabinet.esp[inst] = nil
end
local function cabinetApply(inst)
    if not inst or not inst.Parent or EspCabinet.esp[inst] then return end
    local hl = Instance.new("Highlight")
    hl.Name="BabisCabinetHL"; hl.FillColor=EspCabinet.color; hl.FillTransparency=EspCabinet.fillTrans
    hl.OutlineColor=EspCabinet.color; hl.OutlineTransparency=EspCabinet.outlineTrans
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = inst; hl.Parent = inst
    EspCabinet.esp[inst] = hl
end
local function cabinetClearAll()
    for inst in pairs(EspCabinet.esp) do cabinetClearESP(inst) end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Highlight") and d.Name == "BabisCabinetHL" then d:Destroy() end
    end
end
local function cabinetRescan()
    local closets = cabinetFindAll(); local aliveSet = {}
    for _, c in ipairs(closets) do aliveSet[c]=true; cabinetApply(c) end
    for inst, hl in pairs(EspCabinet.esp) do
        if not inst.Parent or not aliveSet[inst] then if hl then hl:Destroy() end; EspCabinet.esp[inst] = nil end
    end
end
function EspCabinet.enable()
    EspCabinet.enabled = true
    task.spawn(function() task.wait(0.1); cabinetRescan() end)
    if not EspCabinet.loop then
        EspCabinet.loop = task.spawn(function() while alive do task.wait(EspCabinet.scanInterval); if EspCabinet.enabled then pcall(cabinetRescan) end end end)
    end
end
function EspCabinet.disable() EspCabinet.enabled = false; cabinetClearAll() end

local AntiDebris = { enabled = false, folderName = "HulkDebris", prefixes = {"HulkDebrisChunk", "Debris", "Fragment", "Chunk", "HulkDebris"} }
local function adMatches(name)
    for _, p in ipairs(AntiDebris.prefixes) do if name:find(p, 1, true) then return true end end
    return false
end
local function adNuke(inst) if inst then pcall(function() inst:Destroy() end) end end
local adFolderConn, adWatched
function AntiDebris.enable()
    if AntiDebris.enabled then return end
    AntiDebris.enabled = true
    task.spawn(function()
        while AntiDebris.enabled do
            task.wait()
            local folder = Workspace:FindFirstChild(AntiDebris.folderName)
            if folder then for _, c in ipairs(folder:GetChildren()) do adNuke(c) end end
            for _, c in ipairs(Workspace:GetChildren()) do
                if (c:IsA("BasePart") or c:IsA("Model")) and adMatches(c.Name) then adNuke(c) end
            end
        end
    end)
    task.spawn(function()
        while AntiDebris.enabled do
            local f = Workspace:FindFirstChild(AntiDebris.folderName)
            if f ~= adWatched then
                if adFolderConn then pcall(function() adFolderConn:Disconnect() end) end
                adWatched = f
                if f then adFolderConn = f.ChildAdded:Connect(function(child) if AntiDebris.enabled then adNuke(child) end end) end
            end
            task.wait(1)
        end
    end)
end
function AntiDebris.disable()
    AntiDebris.enabled = false
    if adFolderConn then pcall(function() adFolderConn:Disconnect() end) end
    adFolderConn = nil; adWatched = nil
end

local EventLog = {
    enabled = false, gui = nil, container = nil, entries = {}, hitCooldown = {},
    cfg = { fadeInTime=0.15, holdTime=2.6, fadeOutTime=0.4, maxLines=6, hitCooldown=1.0 },
    colors = { hulk=Color3.fromRGB(60,220,100), hulkbuster=Color3.fromRGB(255,200,40),
        survivor=Color3.fromRGB(255,90,90), death=Color3.fromRGB(200,40,40) },
}
local function elGetRole(plr)
    local ch = plr.Character
    if not ch then return "survivor" end
    if ch:GetAttribute("IsHulk") == true or ch:GetAttribute("Transforming") == true then return "hulk" end
    if plr:GetAttribute("HulkbusterActive") == true or ch:GetAttribute("HulkbusterActive") == true then return "hulkbuster" end
    return "survivor"
end
local function elPush(text, color)
    if not EventLog.container then return end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency=1; label.Size=UDim2.new(1,0,0,32); label.Text=text
    label.TextColor3=color; label.Font=Enum.Font.GothamBlack; label.TextSize=22
    label.TextStrokeTransparency=0; label.TextStrokeColor3=Color3.new(0,0,0)
    label.TextXAlignment=Enum.TextXAlignment.Center; label.TextYAlignment=Enum.TextYAlignment.Center
    label.TextTransparency=1; label.LayoutOrder = math.floor(tick()*1000) % 100000
    label.Parent = EventLog.container
    TweenService:Create(label, TweenInfo.new(EventLog.cfg.fadeInTime), {TextTransparency=0}):Play()
    table.insert(EventLog.entries, { text=text, label=label, expires=tick()+EventLog.cfg.holdTime })
    while #EventLog.entries > EventLog.cfg.maxLines do
        local oldest = table.remove(EventLog.entries, 1)
        if oldest and oldest.label.Parent then oldest.label:Destroy() end
    end
end
local function elBind(plr)
    if plr == LocalPlayer then return end
    task.spawn(function()
        while EventLog.enabled and plr.Parent do
            local ch = plr.Character
            if ch then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum then
                    local lastHP = hum.Health
                    local conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
                        local hp = hum.Health
                        if hp < lastHP - 0.5 then
                            local now = tick()
                            if not EventLog.hitCooldown[plr] or now - EventLog.hitCooldown[plr] > EventLog.cfg.hitCooldown then
                                EventLog.hitCooldown[plr] = now
                                local role = elGetRole(plr)
                                local curHP = math.max(0, math.floor(hp))
                                local txt, col
                                if role == "hulk" then txt="HULK "..plr.Name.." was hit ("..curHP.." HP)"; col=EventLog.colors.hulk
                                elseif role == "hulkbuster" then txt="HULKBUSTER "..plr.Name.." was hit ("..curHP.." HP)"; col=EventLog.colors.hulkbuster
                                else txt=plr.Name.." was hit ("..curHP.." HP)"; col=EventLog.colors.survivor end
                                elPush(txt, col)
                            end
                        end
                        lastHP = hp
                    end)
                    plr.CharacterAdded:Wait(); conn:Disconnect()
                else task.wait(0.3) end
            else task.wait(0.3) end
        end
    end)
end
function EventLog.enable()
    if EventLog.enabled then return end
    EventLog.enabled = true
    local sg = Instance.new("ScreenGui")
    sg.Name="BabisEventLog"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.DisplayOrder=999996; sg.Parent=uiParent
    EventLog.gui = sg
    local c = Instance.new("Frame")
    c.Size=UDim2.new(0,520,0,240); c.Position=UDim2.new(0.5,-260,1,-270)
    c.BackgroundTransparency=1; c.BorderSizePixel=0; c.Parent=sg
    EventLog.container = c
    local lay = Instance.new("UIListLayout")
    lay.FillDirection=Enum.FillDirection.Vertical; lay.HorizontalAlignment=Enum.HorizontalAlignment.Center
    lay.VerticalAlignment=Enum.VerticalAlignment.Bottom; lay.Padding=UDim.new(0,6)
    lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Parent=c
    EventLog.entries = {}; EventLog.hitCooldown = {}
    for _, plr in ipairs(Players:GetPlayers()) do elBind(plr) end
    Players.PlayerAdded:Connect(elBind)
    task.spawn(function()
        while EventLog.enabled do
            task.wait(0.1)
            local now = tick()
            for i = #EventLog.entries, 1, -1 do
                local e = EventLog.entries[i]
                if not e.label.Parent then table.remove(EventLog.entries, i)
                elseif now > e.expires then
                    if e.label.Parent then e.label:Destroy() end
                    table.remove(EventLog.entries, i)
                end
            end
        end
    end)
end
function EventLog.disable()
    EventLog.enabled = false
    for _, e in ipairs(EventLog.entries) do if e.label.Parent then e.label:Destroy() end end
    EventLog.entries = {}
    if EventLog.gui then EventLog.gui:Destroy(); EventLog.gui = nil end
    EventLog.container = nil
end

local HulkAlert = { enabled = false, gui = nil, container = nil, titleLbl = nil, infoLbl = nil, barFill = nil, lastStage = nil, pulseT = 0, conn = nil,
    cfg = { safeRange=200, nearbyRange=130, closeRange=60 },
    colors = { safe=Color3.fromRGB(60,220,100), nearby=Color3.fromRGB(255,220,60), close=Color3.fromRGB(255,140,40), danger=Color3.fromRGB(255,50,50) },
    labels = { safe="HULK FAR — SAFE", nearby="HULK NEARBY", close="HULK CLOSE", danger="DANGER — HULK ON YOU" } }
local function haIsHulk(plr)
    local ch = plr.Character; if not ch then return false end
    return ch:GetAttribute("IsHulk") == true or ch:GetAttribute("Transforming") == true
end
local function haFindHulk()
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil, nil end
    local best, bestD
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and haIsHulk(plr) then
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if not bestD or d < bestD then best, bestD = plr, d end
            end
        end
    end
    return best, bestD
end
function HulkAlert.enable()
    if HulkAlert.enabled then return end
    HulkAlert.enabled = true
    local sg = Instance.new("ScreenGui")
    sg.Name="BabisHulkAlert"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.DisplayOrder=999998; sg.Parent=uiParent
    HulkAlert.gui = sg
    local c = Instance.new("Frame")
    c.Size=UDim2.new(0,460,0,90); c.Position=UDim2.new(0.5,-230,0,80)
    c.BackgroundTransparency=1; c.BorderSizePixel=0; c.Visible=false; c.Parent=sg
    HulkAlert.container = c
    local t = Instance.new("TextLabel")
    t.Size=UDim2.new(1,0,0,44); t.BackgroundTransparency=1; t.Text=HulkAlert.labels.safe
    t.TextColor3=HulkAlert.colors.safe; t.Font=Enum.Font.GothamBlack
    t.TextSize=32; t.TextStrokeTransparency=0; t.TextStrokeColor3=Color3.new(0,0,0)
    t.TextXAlignment=Enum.TextXAlignment.Center; t.Parent=c
    HulkAlert.titleLbl = t
    local i = Instance.new("TextLabel")
    i.Size=UDim2.new(1,0,0,24); i.Position=UDim2.new(0,0,0,48)
    i.BackgroundTransparency=1; i.Text="[--- studs]  ·  Name"
    i.TextColor3=HulkAlert.colors.safe; i.Font=Enum.Font.GothamBold
    i.TextSize=18; i.TextStrokeTransparency=0; i.TextStrokeColor3=Color3.new(0,0,0)
    i.TextXAlignment=Enum.TextXAlignment.Center; i.Parent=c
    HulkAlert.infoLbl = i
    local bg = Instance.new("Frame")
    bg.Size=UDim2.new(1,-40,0,3); bg.Position=UDim2.new(0,20,0,78)
    bg.BackgroundColor3=Color3.fromRGB(0,0,0); bg.BackgroundTransparency=0.7
    bg.BorderSizePixel=0; bg.Parent=c; corner(bg, 1)
    local fill = Instance.new("Frame")
    fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=HulkAlert.colors.safe
    fill.BorderSizePixel=0; fill.Parent=bg; corner(fill, 1)
    HulkAlert.barFill = fill
    HulkAlert.conn = RunService.RenderStepped:Connect(function(dt)
        if not HulkAlert.enabled then return end
        local plr, dist = haFindHulk()
        if not plr or not dist then if c.Visible then c.Visible = false end; HulkAlert.lastStage = nil; return end
        if not c.Visible then c.Visible = true end
        local stage
        if dist > HulkAlert.cfg.safeRange then stage = "safe"
        elseif dist > HulkAlert.cfg.nearbyRange then stage = "nearby"
        elseif dist > HulkAlert.cfg.closeRange then stage = "close"
        else stage = "danger" end
        local color = HulkAlert.colors[stage]
        if HulkAlert.lastStage ~= stage then
            HulkAlert.lastStage = stage
            TweenService:Create(t, TweenInfo.new(0.2), {TextColor3=color}):Play()
            TweenService:Create(i, TweenInfo.new(0.2), {TextColor3=color}):Play()
            TweenService:Create(fill, TweenInfo.new(0.2), {BackgroundColor3=color}):Play()
        end
        local pct = math.clamp(1 - (dist / 200), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        t.Text = HulkAlert.labels[stage]
        i.Text = string.format("[%d studs]  ·  %s", math.floor(dist), plr.Name)
        if stage == "danger" then
            HulkAlert.pulseT = HulkAlert.pulseT + dt * 10
            local pulse = 0.5 + 0.5 * math.sin(HulkAlert.pulseT)
            t.TextColor3 = Color3.fromRGB(255, math.floor(50 + pulse*90), math.floor(50 + pulse*90))
            t.TextSize = math.floor(32 * (1 + pulse*0.08)); i.TextSize = math.floor(18 * (1 + pulse*0.08))
        elseif stage == "close" then
            HulkAlert.pulseT = HulkAlert.pulseT + dt * 6
            local pulse = 0.5 + 0.5 * math.sin(HulkAlert.pulseT)
            t.TextColor3 = Color3.fromRGB(math.floor(240+pulse*15), math.floor(120+pulse*40), math.floor(20+pulse*20))
            t.TextSize = 32; i.TextSize = 18
        else
            t.TextSize = 32; i.TextSize = 18; t.TextColor3 = color; i.TextColor3 = color
        end
    end)
end
function HulkAlert.disable()
    HulkAlert.enabled = false
    if HulkAlert.conn then HulkAlert.conn:Disconnect(); HulkAlert.conn = nil end
    if HulkAlert.gui then HulkAlert.gui:Destroy(); HulkAlert.gui = nil end
    HulkAlert.container = nil; HulkAlert.titleLbl = nil; HulkAlert.infoLbl = nil; HulkAlert.barFill = nil
end

local Panic = { autoTrigger=false, triggerRadius=45, cooldown=5, topN=10, sampleStep=16, minHulkDist=90,
    inset=10, offsetY=3, maxYDelta=6, centerBias=1.0, centerRadius=120,
    points={}, hulkPos=nil, best=nil, lastTP=0, yRange=nil, center=nil }
local function panicGetChar() return LocalPlayer.Character end
local function panicGetHrp() local ch = panicGetChar(); return ch and ch:FindFirstChild("HumanoidRootPart") end
local function panicFindFacility()
    local f = Workspace:FindFirstChild("HulkFacility440x340")
    if f then return f end
    for _, d in ipairs(Workspace:GetChildren()) do if d:IsA("Model") and d.Name:lower():match("hulkfacility") then return d end end
    return nil
end
local function panicFindFloors()
    local fac = panicFindFacility(); if not fac then return nil end
    local fl = fac:FindFirstChild("Floors"); if not fl then return nil end
    return {room=fl:FindFirstChild("RoomFloors"), corridor=fl:FindFirstChild("CorridorFloors"), facility=fac}
end
local function panicComputeYRange(fac)
    local mn, mx = math.huge, -math.huge
    for _, d in ipairs(fac:GetDescendants()) do
        if d:IsA("BasePart") then mn=math.min(mn, d.Position.Y); mx=math.max(mx, d.Position.Y) end
    end
    if mn == math.huge then return nil end
    return {min=mn, max=mx}
end
local function panicComputeCenter(fac)
    local sum, count = Vector3.zero, 0
    for _, d in ipairs(fac:GetDescendants()) do if d:IsA("BasePart") then sum = sum + d.Position; count = count + 1 end end
    if count == 0 then return nil end
    return sum / count
end
local function panicSampleFolder(folder, tag)
    if not folder then return end
    local ch = panicGetChar(); local step = Panic.sampleStep; local inset = Panic.inset
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") and not part.Name:lower():match("water") then
            local topY = part.Position.Y + part.Size.Y * 0.5
            local hX = math.max(part.Size.X * 0.5 - inset, 0)
            local hZ = math.max(part.Size.Z * 0.5 - inset, 0)
            for xO = -hX, hX, step do
                for zO = -hZ, hZ, step do
                    local ray = Ray.new(Vector3.new(part.Position.X + xO, topY + 1, part.Position.Z + zO), Vector3.new(0,-20,0))
                    local hit, hp = Workspace:FindPartOnRay(ray, ch)
                    if hit and hp and math.abs(hp.Y - topY) <= Panic.maxYDelta then
                        Panic.points[#Panic.points+1] = {pos=Vector3.new(hp.X, hp.Y + Panic.offsetY, hp.Z), tag=tag}
                    end
                end
            end
        end
    end
end
local function panicRescan()
    Panic.points = {}
    local f = panicFindFloors(); if not f then return end
    Panic.yRange = panicComputeYRange(f.facility)
    Panic.center = panicComputeCenter(f.facility)
    panicSampleFolder(f.room, "room"); panicSampleFolder(f.corridor, "corridor")
end
local function panicFindHulk()
    local hrp = panicGetHrp(); if not hrp then return nil end
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:GetAttribute("IsHulk") then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            if h then
                local d = (h.Position - hrp.Position).Magnitude
                if not bestD or d < bestD then best, bestD = h, d end
            end
        end
    end
    return best, bestD
end
local function panicPickSafe()
    if #Panic.points == 0 then return nil end
    local hrp = panicGetHrp(); if not hrp then return nil end
    local myPos = hrp.Position; local scored = {}
    for _, pt in ipairs(Panic.points) do
        if not Panic.yRange or (pt.pos.Y >= Panic.yRange.min - 5 and pt.pos.Y <= Panic.yRange.max + 5) then
            local hD = Panic.hulkPos and (pt.pos - Panic.hulkPos).Magnitude or 999
            if hD >= Panic.minHulkDist then
                local centerBonus = 0
                if Panic.center and Panic.centerRadius > 0 then
                    local distToCenter = (pt.pos - Panic.center).Magnitude
                    if distToCenter < Panic.centerRadius then centerBonus = (Panic.centerRadius - distToCenter) * Panic.centerBias end
                end
                local myPenalty = math.min((pt.pos - myPos).Magnitude, 250) * 0.05
                scored[#scored+1] = {pt=pt, score=hD + centerBonus - myPenalty}
            end
        end
    end
    if #scored == 0 then
        for _, pt in ipairs(Panic.points) do
            local hD = Panic.hulkPos and (pt.pos - Panic.hulkPos).Magnitude or 999
            scored[#scored+1] = {pt=pt, score=hD}
        end
    end
    table.sort(scored, function(a, b) return a.score > b.score end)
    local topN = math.min(Panic.topN, #scored); if topN == 0 then return nil end
    return scored[math.random(1, topN)].pt
end
local function panicDo()
    if tick() - Panic.lastTP < Panic.cooldown then return false end
    local pt = panicPickSafe(); if not pt then return false end
    local ch = panicGetChar(); if not ch then return false end
    local ok = pcall(function() ch:PivotTo(CFrame.new(pt.pos)) end)
    if ok then Panic.lastTP = tick(); Panic.best = pt.pos; showClimbOverlay(1.2); return true end
    return false
end
task.spawn(function() task.wait(2); panicRescan() end)
task.spawn(function() while alive do task.wait(10); if #Panic.points == 0 then pcall(panicRescan) end end end)
task.spawn(function() while alive do task.wait(0.25); local h = panicFindHulk(); Panic.hulkPos = h and h.Position or nil end end)
RunService.Heartbeat:Connect(function()
    if not Panic.autoTrigger then return end
    local _, d = panicFindHulk()
    if d and d <= Panic.triggerRadius then panicDo() end
end)
function Panic.setAuto(v) Panic.autoTrigger = v end
function Panic.fireManual() return panicDo() end

local function flingTargetCFrame(hulkHrp)
    local char = hulkHrp.Parent
    local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso"))
    if torso then return torso.CFrame end
    return hulkHrp.CFrame
end

local Fling = { running = false, startedAt = 0, tpAt = 0, savedCFrame = nil, phase = "idle", returnsDone = 0, aborted = false, hulkName = "—",
    duration = 1.5, linearForce = DEFAULT_FLING_SPEED, maxDrift = 12,
    returnTPs = 4, returnDelay = 0.15, settleDelay = 0.20,
    spinForce = DEFAULT_FLING_SPEED * FLING_SPIN_MULT, predictOffset = 1, savedHealth = nil }

local function flingGetChar() return LocalPlayer.Character end
local function flingGetHum() local ch = flingGetChar(); return ch and ch:FindFirstChildOfClass("Humanoid") end
local function flingGetHrp() local ch = flingGetChar(); return ch and ch:FindFirstChild("HumanoidRootPart") end
local function flingFindHulk()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:GetAttribute("IsHulk") then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp, p end
        end
    end
    return nil
end
local function flingPredictTarget(hulkHrp)
    local base = flingTargetCFrame(hulkHrp).Position
    local offset = Fling.predictOffset or 0
    if offset == 0 then return base end
    local vel = hulkHrp.AssemblyLinearVelocity
    local speed = vel.Magnitude
    if speed < 0.5 then return base + hulkHrp.CFrame.LookVector * offset end
    return base + vel.Unit * offset
end
local function flingResetSelf()
    local hrp = flingGetHrp(); if not hrp then return end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
end
local function flingReturnHome()
    if not Fling.savedCFrame then return end
    local ch = flingGetChar(); if not ch then return end
    Fling.phase = "returning"; Fling.returnsDone = 0
    task.spawn(function()
        for i = 1, Fling.returnTPs do
            if not ch.Parent then break end
            pcall(function() ch:PivotTo(Fling.savedCFrame) end)
            flingResetSelf(); Fling.returnsDone = i; task.wait(Fling.returnDelay)
        end
        Fling.phase = "idle"; Fling.savedCFrame = nil
    end)
end
local function flingStop(aborted)
    if aborted then Fling.aborted = true end
    Fling.running = false; flingResetSelf(); flingReturnHome()
end
RunService.Heartbeat:Connect(function()
    if not Fling.running then return end
    local hum = flingGetHum()
    if hum and Fling.savedHealth and hum.Health < Fling.savedHealth then safeWrite(hum, "Health", Fling.savedHealth) end
    if not hum or hum.Health <= 0 then flingStop(true); return end
    if tick() - Fling.startedAt >= Fling.duration then flingStop(); return end
    local myHrp = flingGetHrp(); if not myHrp then return end
    local hulkHrp, hulkPlayer = flingFindHulk()
    if not hulkHrp then Fling.hulkName = "no hulk"; return end
    Fling.hulkName = hulkPlayer.Name
    local ch = flingGetChar(); if not ch then return end
    local targetPos = flingPredictTarget(hulkHrp)
    local hulkPos = flingTargetCFrame(hulkHrp).Position
    local myPos = myHrp.Position
    local distToReal = (myPos - hulkPos).Magnitude
    local distToPred = (myPos - targetPos).Magnitude
    if Fling.phase == "tp" then
        pcall(function() ch:PivotTo(CFrame.new(targetPos)) end)
        flingResetSelf(); Fling.tpAt = tick(); Fling.phase = "settle"; return
    end
    if Fling.phase == "settle" then
        if tick() - Fling.tpAt < Fling.settleDelay then return end
        Fling.phase = "force"
    end
    if Fling.phase == "force" then
        if distToPred > Fling.maxDrift then pcall(function() ch:PivotTo(CFrame.new(targetPos)) end); flingResetSelf() end
        if distToReal > Fling.maxDrift * 2 then pcall(function() ch:PivotTo(CFrame.new(targetPos)) end); flingResetSelf() end
        pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero; myHrp.AssemblyAngularVelocity = Vector3.zero end)
        local f = Fling.linearForce; local s = Fling.spinForce
        pcall(function()
            myHrp.AssemblyLinearVelocity = Vector3.new(f, f * 0.05, f)
            myHrp.AssemblyAngularVelocity = Vector3.new(s, s, s)
        end)
    end
end)
function Fling.fire()
    if Fling.running then return false end
    local hrp = flingGetHrp(); if not hrp then return false end
    local hulkHrp = flingFindHulk(); if not hulkHrp then notify("Kill Hulk", "No Hulk present", 2, "warn"); return false end
    Fling.savedCFrame = hrp.CFrame
    local hum = flingGetHum()
    if hum then Fling.savedHealth = hum.MaxHealth end
    Fling.running = true; Fling.startedAt = tick(); Fling.tpAt = 0
    Fling.phase = "tp"; Fling.returnsDone = 0; Fling.aborted = false
    showKillOverlay(2.0)
    return true
end

local AutoKill = {
    enabled = false, cycles = 4, cycleDelay = 0.35, flingBurst = 0.40,
    burstForce = DEFAULT_FLING_SPEED, burstSpin = DEFAULT_FLING_SPEED * FLING_SPIN_MULT,
    pinMaxDist = 8, overlayDuration = 6.0, onlySurvivor = true,
    survivorTeamNames = { "Survivors", "Survivor", "Players", "Blue" },
    lobbyTeamNames = { "Lobby", "Spectators", "Waiting", "Spectator" },
    useFallback = true, running = false, cyclesDone = 0, targetName = nil,
    originalCFrame = nil, lastTriggerAt = 0, cooldown = 3.0,
    savedHealth = nil, _charsWatched = setmetatable({}, { __mode = "k" }),
}
local function autoKillIsSurvivor()
    local team = LocalPlayer.Team
    if team and team.Name then
        for _, n in ipairs(AutoKill.survivorTeamNames) do if team.Name == n then return true end end
        for _, n in ipairs(AutoKill.lobbyTeamNames) do if team.Name == n then return false end end
        return true
    end
    if AutoKill.useFallback then
        local ch = LocalPlayer.Character
        if ch then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return true end
        end
    end
    return false
end
local function autoKillBurst(targetChar)
    local ch = LocalPlayer.Character
    local myHrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local burstStart = tick()
    while tick() - burstStart < AutoKill.flingBurst do
        if not AutoKill.enabled then break end
        if not ch.Parent then break end
        if hum and AutoKill.savedHealth and hum.Health < AutoKill.savedHealth then safeWrite(hum, "Health", AutoKill.savedHealth) end
        local tgtHrp = targetChar:FindFirstChild("HumanoidRootPart")
        myHrp = ch:FindFirstChild("HumanoidRootPart")
        if not tgtHrp or not myHrp then break end
        local targetTorso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("LowerTorso")
        local insideCFrame = targetTorso and targetTorso.CFrame or tgtHrp.CFrame
        local d = (myHrp.Position - tgtHrp.Position).Magnitude
        if d > AutoKill.pinMaxDist then pcall(function() ch:PivotTo(insideCFrame) end) end
        pcall(function()
            myHrp.AssemblyLinearVelocity = Vector3.new(AutoKill.burstForce, AutoKill.burstForce * 0.05, AutoKill.burstForce)
            myHrp.AssemblyAngularVelocity = Vector3.new(AutoKill.burstSpin, AutoKill.burstSpin, AutoKill.burstSpin)
        end)
        task.wait()
    end
end
local function autoKillRun(targetChar, targetName)
    if AutoKill.running then return end
    if tick() - AutoKill.lastTriggerAt < AutoKill.cooldown then return end
    AutoKill.lastTriggerAt = tick()
    if AutoKill.onlySurvivor and not autoKillIsSurvivor() then return end
    AutoKill.running = true; AutoKill.cyclesDone = 0; AutoKill.targetName = targetName
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then AutoKill.running = false; return end
    AutoKill.originalCFrame = hrp.CFrame
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then AutoKill.savedHealth = hum.MaxHealth end
    showKillOverlay(AutoKill.overlayDuration)
    task.spawn(function()
        for i = 1, AutoKill.cycles do
            if not AutoKill.enabled then break end
            ch = LocalPlayer.Character
            if not ch or not ch.Parent then break end
            local tgtHrp = targetChar:FindFirstChild("HumanoidRootPart")
            if not tgtHrp then break end
            local targetTorso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("LowerTorso")
            local insideCFrame = targetTorso and targetTorso.CFrame or tgtHrp.CFrame
            pcall(function() ch:PivotTo(insideCFrame) end)
            task.wait(0.08)
            autoKillBurst(targetChar)
            if AutoKill.originalCFrame then
                for r = 1, 4 do
                    pcall(function() ch:PivotTo(AutoKill.originalCFrame) end)
                    local h2 = ch:FindFirstChild("HumanoidRootPart")
                    if h2 then pcall(function() h2.AssemblyLinearVelocity = Vector3.zero; h2.AssemblyAngularVelocity = Vector3.zero end) end
                    local hum2 = ch:FindFirstChildOfClass("Humanoid")
                    if hum2 and AutoKill.savedHealth and hum2.Health < AutoKill.savedHealth then safeWrite(hum2, "Health", AutoKill.savedHealth) end
                    task.wait(0.12)
                end
            end
            AutoKill.cyclesDone = i
            task.wait(AutoKill.cycleDelay)
        end
        AutoKill.running = false; AutoKill.savedHealth = nil
    end)
end
local function autoKillWatchChar(c, plr)
    if not c or AutoKill._charsWatched[c] then return end
    AutoKill._charsWatched[c] = true
    c.AttributeChanged:Connect(function(name)
        if name ~= "Transforming" then return end
        if not AutoKill.enabled or AutoKill.running or plr == LocalPlayer then return end
        if c:GetAttribute("Transforming") == true then
            if not autoKillIsSurvivor() then return end
            autoKillRun(c, plr.Name)
        end
    end)
end
local function autoKillWatchPlayer(plr)
    if not plr then return end
    if plr.Character then autoKillWatchChar(plr.Character, plr) end
    plr.CharacterAdded:Connect(function(c) task.wait(0.3); autoKillWatchChar(c, plr) end)
end
for _, plr in ipairs(Players:GetPlayers()) do autoKillWatchPlayer(plr) end
Players.PlayerAdded:Connect(autoKillWatchPlayer)
function AutoKill.setEnabled(v)
    AutoKill.enabled = v and true or false
    if not AutoKill.enabled then AutoKill.running = false; AutoKill.savedHealth = nil end
end

local Doors = { enabled=false, invisible=true, noCollide=true, scanInterval=4,
    keywords={"door","gate","exit","porta","entrance","hinge","doorway","portal"},
    originals={}, loop=nil, addConn=nil }
local function doorNameMatches(name)
    local n = name:lower()
    for _, kw in ipairs(Doors.keywords) do if n:match(kw) then return true end end
    return false
end
local function doorIsPlayerPart(part)
    local p = part.Parent
    while p and p ~= Workspace do
        if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then return true end
        p = p.Parent
    end
    return false
end
local function doorCapture(part)
    if Doors.originals[part] then return end
    Doors.originals[part] = {transp=part.Transparency, cc=part.CanCollide, cq=part.CanQuery, ct=part.CanTouch}
end
local function doorApply(part)
    if not part or not part.Parent or not part:IsA("BasePart") then return end
    if doorIsPlayerPart(part) then return end
    doorCapture(part)
    if Doors.invisible then part.Transparency = 1 end
    if Doors.noCollide then part.CanCollide=false; part.CanQuery=false; part.CanTouch=false end
end
local function doorRestore()
    for part, o in pairs(Doors.originals) do
        if part and part.Parent then
            pcall(function() part.Transparency=o.transp; part.CanCollide=o.cc; part.CanQuery=o.cq; part.CanTouch=o.ct end)
        end
    end
    Doors.originals = {}
end
local function doorScan()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and doorNameMatches(d.Name) then doorApply(d) end
        if d:IsA("Model") and doorNameMatches(d.Name) then
            for _, ch in ipairs(d:GetDescendants()) do if ch:IsA("BasePart") then doorApply(ch) end end
        end
    end
end
function Doors.enable()
    Doors.enabled = true
    task.spawn(function() task.wait(0.1); doorScan() end)
    if not Doors.loop then Doors.loop = task.spawn(function() while alive do task.wait(Doors.scanInterval); if Doors.enabled then pcall(doorScan) end end end) end
    if not Doors.addConn then
        Doors.addConn = Workspace.DescendantAdded:Connect(function(d)
            if not Doors.enabled then return end
            if d:IsA("BasePart") and doorNameMatches(d.Name) then task.wait(0.1); doorApply(d) end
        end)
    end
end
function Doors.disable() Doors.enabled = false; doorRestore() end

local HulkAttack = ReplicatedStorage:FindFirstChild("HulkAttack")
local HulkSkinSystem = ReplicatedStorage:FindFirstChild("HulkSkinSystem")
if not HulkSkinSystem then
    task.spawn(function() HulkSkinSystem = ReplicatedStorage:WaitForChild("HulkSkinSystem", 30) end)
end
local function skinRemote(name)
    if HulkSkinSystem then return HulkSkinSystem:FindFirstChild(name) end
end

local SharedData = { money = 0, cost = 1000, pity = 0, pityLimit = 150,
    owned = {}, equipped = nil, missions = {}, dailyCanClaim = false, lastData = nil }

local AutoPunch = { running = false, count = 0, rateClock = 0, rateCount = 0 }
local function getLocalRoot()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
RunService.RenderStepped:Connect(function(dt)
    if not AutoPunch.running then
        if AutoPunch.rateClock > 0 then AutoPunch.rateClock = 0; AutoPunch.rateCount = 0 end
        return
    end
    if HulkAttack then
        local root = getLocalRoot()
        if root then
            pcall(function() HulkAttack:FireServer(root.CFrame, Vector3.new(0, 0, 0)) end)
            AutoPunch.count = AutoPunch.count + 1
            AutoPunch.rateCount = AutoPunch.rateCount + 1
        end
    end
    AutoPunch.rateClock = AutoPunch.rateClock + dt
    if AutoPunch.rateClock >= 0.5 then
        AutoPunch.rateClock = 0; AutoPunch.rateCount = 0
    end
end)
function AutoPunch.setEnabled(v)
    AutoPunch.running = v and true or false
    if AutoPunch.running and not HulkAttack then
        notify("Auto Punch", "HulkAttack remote not found — punch may fail", 2.5, "warn")
    end
end

local function readState()
    local EmoteSpin = skinRemote("EmoteSpin")
    if EmoteSpin then
        local ok, res = pcall(function() return EmoteSpin:InvokeServer() end)
        if ok and type(res) == "table" and res.Data then return res.Data, res.Success end
    end
    return nil
end
local function absorbState(data)
    if not data then return end
    SharedData.lastData = data
    SharedData.money = data.Money or 0
    SharedData.cost = data.AbilitySpinCost or 1000
    SharedData.pity = data.AbilityPity or 0
    SharedData.pityLimit = data.AbilityPityLimit or 150
    SharedData.owned = data.OwnedAbilities or {}
    SharedData.equipped = data.EquippedAbility
    SharedData.missions = data.Missions or {}
    SharedData.dailyCanClaim = data.Daily and data.Daily.CanClaim or false
end

local AutoMission = { enabled = false, interval = 3, running = false }
local function claimAllMissions()
    if AutoMission.running then return end
    AutoMission.running = true
    if not skinRemote("ClaimMission") and not SharedData.lastData then
        local data = readState()
        if data then absorbState(data) end
    end
    local ClaimMission = skinRemote("ClaimMission")
    local ClaimDaily = skinRemote("ClaimDaily")
    if not ClaimMission and not ClaimDaily then AutoMission.running = false; return end

    local missions = SharedData.missions or {}
    local idxs = {}
    for i, m in pairs(missions) do
        if m.Completed and not m.Claimed then idxs[#idxs + 1] = i end
    end
    table.sort(idxs)

    local claimed, gained = 0, 0
    local before = SharedData.money or 0

    for _, i in ipairs(idxs) do
        if not AutoMission.enabled then break end
        local ok, res = pcall(function() return ClaimMission:InvokeServer(i) end)
        if ok and type(res) == "table" then
            if res.Data then absorbState(res.Data) end
            if res.Success == true then claimed = claimed + 1 end
        end
        task.wait(0.1)
    end

    if SharedData.dailyCanClaim and ClaimDaily then
        local ok, res = pcall(function() return ClaimDaily:InvokeServer() end)
        if ok and type(res) == "table" and res.Data then absorbState(res.Data) end
    end

    if #idxs > 0 then
        gained = (SharedData.money or 0) - before
        if gained ~= 0 or claimed > 0 then
            notify("Auto Mission", string.format("+$%d · %d/%d claimed", gained, claimed, #idxs), 2, "success")
        end
    end
    AutoMission.running = false
end
task.spawn(function()
    while alive do
        task.wait(AutoMission.interval)
        if AutoMission.enabled then pcall(claimAllMissions) end
    end
end)
function AutoMission.setEnabled(v)
    AutoMission.enabled = v and true or false
    if AutoMission.enabled then
        task.spawn(function() pcall(claimAllMissions) end)
        notify("Auto Mission", "Started — claiming every " .. AutoMission.interval .. "s", 2, "info")
    end
end

local SpinSystem = {
    running = false, target = nil, attempts = 0, spent = 0,
    renderAbilities = nil,
}
local function spinOnce()
    local AbilitySpin = skinRemote("AbilitySpin")
    if not AbilitySpin then return nil end
    local ok, res = pcall(function() return AbilitySpin:InvokeServer() end)
    if ok and type(res) == "table" then return res end
    return nil
end
local function canAffordSpin()
    if (SharedData.money or 0) > 0 and (SharedData.cost or 1000) <= (SharedData.money or 0) then return true end
    local last = SharedData.lastData
    if last and (last.AbilitySpins or 0) > 0 then return true end
    return (SharedData.money or 0) >= (SharedData.cost or 1000)
end
local function stopSpin(reason)
    if not SpinSystem.running then return end
    SpinSystem.running = false
    if reason then notify("Spin", "STOP: " .. reason, 2.5, "warn") end
end
local function startSpin()
    if not SpinSystem.target then notify("Spin", "Select a MISSING ability first", 2, "error"); return end
    if SharedData.owned[SpinSystem.target] then notify("Spin", SpinSystem.target .. " is already owned", 2, "warn"); return end
    if not canAffordSpin() then notify("Spin", "No spins and no money", 2, "error"); return end
    SpinSystem.running = true
    SpinSystem.attempts = 0
    SpinSystem.spent = 0
    notify("Spin", "Hunting: " .. SpinSystem.target, 2, "success")
    task.spawn(function()
        while SpinSystem.running do
            if not SpinSystem.target then stopSpin("target removed"); break end
            if not canAffordSpin() then stopSpin("out of money"); break end
            if SharedData.owned[SpinSystem.target] then stopSpin("ACQUIRED · " .. SpinSystem.target); break end
            local prev = SharedData.money or 0
            local res = spinOnce()
            if not res then
                task.wait(1)
            else
                if res.Data then absorbState(res.Data) end
                if res.Success == true then
                    SpinSystem.attempts = SpinSystem.attempts + 1
                    local delta = prev - (SharedData.money or prev)
                    if delta > 0 then SpinSystem.spent = SpinSystem.spent + delta end
                    if SpinSystem.renderAbilities then pcall(SpinSystem.renderAbilities) end
                    if SharedData.owned[SpinSystem.target] then
                        notify("Spin", "★ GOT " .. SpinSystem.target .. " in " .. SpinSystem.attempts .. " spins!", 3, "success")
                        stopSpin("ACQUIRED · " .. SpinSystem.target)
                        break
                    end
                    task.wait(0.08)
                else
                    local msg = tostring(res.Message or "?"):lower()
                    if msg:find("lobby") then task.wait(2)
                    elseif msg:find("money") or msg:find("fund") or msg:find("insufficient") then stopSpin("out of money"); break
                    else task.wait(1) end
                end
            end
        end
        if SpinSystem.renderAbilities then pcall(SpinSystem.renderAbilities) end
    end)
end
function SpinSystem.setEnabled(v)
    if v then startSpin() else stopSpin("manual") end
end

task.spawn(function()
    while alive do
        task.wait(6)
        if not SpinSystem.running then
            local data = readState()
            if data then absorbState(data); if SpinSystem.renderAbilities then pcall(SpinSystem.renderAbilities) end end
        end
    end
end)

local function addAbilityList(parent, order)
    local wrap = new("Frame", { Name = "Wrap", Size = UDim2.new(1, 0, 0, 220), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
    wrap:SetAttribute("Entrance", true)
    local card = new("Frame", { Name = "Card", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrap })
    corner(card, 10)
    local cardStroke = stroke(card, Theme.c.border, 1, 0)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(212, 212, 218)), Parent = card })

    local title = newLabel(card, "Ability Target", 13, FONT_STRONG, TEXT, { Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 16, 0, 10) })
    local targetLbl = newLabel(card, "none", 11, FONT_CODE, C_ERROR, { Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 16, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })

    local list = new("ScrollingFrame", {
        Size = UDim2.new(1, -20, 0, 168), Position = UDim2.new(0, 10, 0, 50),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.c.accent, ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = card,
    })
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

    local function render()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local names = {}
        for n in pairs(SharedData.owned or {}) do names[#names + 1] = n end
        table.sort(names)

        if SpinSystem.target then
            targetLbl.Text = "target: " .. SpinSystem.target
            targetLbl.TextColor3 = Theme.c.accent
        else
            targetLbl.Text = "target: NONE — click a MISSING ability"
            targetLbl.TextColor3 = C_ERROR
        end

        if #names == 0 then
            new("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Loading ability data...", TextColor3 = TEXT_MUTED, Font = FONT_MAIN, TextSize = 11, ZIndex = 6, Parent = list })
            return
        end

        for i, name in ipairs(names) do
            local owned = SharedData.owned[name] == true
            local equipped = (SharedData.equipped == name)
            local isTarget = (SpinSystem.target == name)
            local row = new("TextButton", {
                Size = UDim2.new(1, -4, 0, 30),
                BackgroundColor3 = isTarget and Theme.c.hover or Theme.c.bgMain,
                BackgroundTransparency = isTarget and 0 or 0.35,
                Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 6, Parent = list,
            })
            corner(row, 6)
            stroke(row, isTarget and Theme.c.accent or (owned and C_SUCCESS or Theme.c.border), isTarget and 1.5 or 1, 0.3)
            local dot = new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 10, 0.5, -4), BackgroundColor3 = owned and C_SUCCESS or C_LOCKED, BorderSizePixel = 0, ZIndex = 7, Parent = row })
            corner(dot, 4)
            newLabel(row, name, 11, FONT_STRONG, owned and TEXT or Color3.fromRGB(120, 120, 128), { Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 24, 0, 0), ZIndex = 7 })
            local badgeText = equipped and "EQUIPPED" or (owned and "OWNED" or "MISSING")
            local badgeCol  = equipped and Theme.c.accent or (owned and C_SUCCESS or C_ERROR)
            local badge = new("TextLabel", { Size = UDim2.fromOffset(70, 18), Position = UDim2.new(1, -78, 0.5, -9), BackgroundColor3 = owned and Color3.fromRGB(20, 40, 25) or Color3.fromRGB(30, 20, 20), Text = badgeText, TextColor3 = badgeCol, Font = FONT_STRONG, TextSize = 8, BorderSizePixel = 0, ZIndex = 7, Parent = row })
            corner(badge, 4)

            row.MouseEnter:Connect(function()
                if not isTarget then tween(row, { BackgroundTransparency = 0, BackgroundColor3 = Theme.c.hover }, 0.1) end
            end)
            row.MouseLeave:Connect(function()
                if not isTarget then tween(row, { BackgroundTransparency = 0.35, BackgroundColor3 = Theme.c.bgMain }, 0.12) end
            end)
            row.MouseButton1Click:Connect(function()
                if SpinSystem.running then
                    notify("Spin", "Stop the spin before changing target", 2, "warn")
                    return
                end
                SpinSystem.target = name
                notify("Spin", "Target: " .. name, 2, "info")
                render()
            end)
        end
    end
    SpinSystem.renderAbilities = render
    task.spawn(function() task.wait(0.5); pcall(render) end)
    task.spawn(function()
        while alive do
            task.wait(6)
            if list.Parent then pcall(render) end
        end
    end)
    return wrap
end

task.delay(1.2, function()
    if not alive then return end
    local data = readState()
    if data then absorbState(data); if SpinSystem.renderAbilities then pcall(SpinSystem.renderAbilities) end end
end)

return {
    AutoKill = AutoKill,
    Fling = Fling,
    PlayerESP = PlayerESP,
    ChanceESP = ChanceESP,
    EspVents = EspVents,
    EspCabinet = EspCabinet,
    AntiDebris = AntiDebris,
    EventLog = EventLog,
    HulkAlert = HulkAlert,
    Panic = Panic,
    InfiniteStamina = InfiniteStamina,
    AntiRagdoll = AntiRagdoll,
    PlayerState = PlayerState,
    applyPlayerState = applyPlayerState,
    AutoPunch = AutoPunch,
    AutoMission = AutoMission,
    SpinSystem = SpinSystem,
    Doors = Doors,
    addAbilityList = addAbilityList,
}
end)()
-- ===== END GAME LOGIC CLOSURE =====

do
    local mainPage = pages["Main"]
    addSectionHeader(mainPage, "COMBAT", 0)
    addToggle(mainPage, "auto_kill_hulk", "Auto Kill Hulk", 10, function(v)
        Game.AutoKill.setEnabled(v)
        notify("Auto Kill Hulk", v and "Watching for transformation" or "Disabled", 2, v and "success" or "info")
    end)
    addClickButton(mainPage, "Kill Hulk Button", CLICK_ICON, 11, function()
        local ok = Game.Fling.fire()
        notify("Kill Hulk", ok and "Fling started" or "No Hulk / abort", 2, ok and "success" or "warn")
    end)
    addSlider(mainPage, "fling_predict", "Kill Predict", -100, 100, 12, function(v) Game.Fling.predictOffset = v end)
    if Options["fling_predict"] == nil then Options["fling_predict"] = 1 end
    Game.Fling.predictOffset = Options["fling_predict"] or 1
    addSlider(mainPage, "fling_speed", "Speed Kill", 100, 1200, 13, function(v)
        Game.Fling.linearForce = v
        Game.Fling.spinForce = v * FLING_SPIN_MULT
        Game.AutoKill.burstForce = v
        Game.AutoKill.burstSpin = v * FLING_SPIN_MULT
    end)
    if Options["fling_speed"] == nil then Options["fling_speed"] = DEFAULT_FLING_SPEED end
    Game.Fling.linearForce = Options["fling_speed"] or DEFAULT_FLING_SPEED
    Game.Fling.spinForce = Game.Fling.linearForce * FLING_SPIN_MULT
    Game.AutoKill.burstForce = Game.Fling.linearForce
    Game.AutoKill.burstSpin = Game.Fling.spinForce
    addSectionHeader(mainPage, "PUNCH", 20)
    addToggle(mainPage, "auto_punch", "Auto Punch (Hulk)", 21, function(v)
        Game.AutoPunch.setEnabled(v)
        notify("Auto Punch", v and "ON — firing HulkAttack" or "OFF", 2, v and "success" or "info")
    end)
end

do
    local visualPage = pages["Visuals"]
    addSectionHeader(visualPage, "PLAYER ESP", 0)
    addToggle(visualPage, "esp_hulk", "ESP Hulk", 10, function(v) Game.PlayerESP.setFlag("hulk", v) end)
    addToggle(visualPage, "esp_hulkbuster", "ESP Hulkbuster", 11, function(v) Game.PlayerESP.setFlag("hulkbuster", v) end)
    addToggle(visualPage, "esp_survivor", "ESP Survivor", 12, function(v) Game.PlayerESP.setFlag("survivor", v) end)
    addToggle(visualPage, "esp_weapons", "ESP Weapons", 13, function(v) Game.PlayerESP.setFlag("weapon", v) end)
    addToggle(visualPage, "esp_ability", "ESP Ability Owners", 14, function(v) Game.PlayerESP.setFlag("abilityHighlight", v) end)
    addSectionHeader(visualPage, "WORLD ESP", 20)
    addToggle(visualPage, "esp_vents", "ESP Vents", 21, function(v) if v then Game.EspVents.enable() else Game.EspVents.disable() end end)
    addToggle(visualPage, "esp_cabinet", "ESP Cabinet", 22, function(v) if v then Game.EspCabinet.enable() else Game.EspCabinet.disable() end end)
    addSectionHeader(visualPage, "INTEL", 30)
    addToggle(visualPage, "esp_hulk_chance", "ESP Hulk Probability + Pity", 31, function(v) if v then Game.ChanceESP.enable() else Game.ChanceESP.disable() end end)
    addToggle(visualPage, "hulk_alert", "Hulk Alert", 32, function(v) if v then Game.HulkAlert.enable() else Game.HulkAlert.disable() end end)
    addToggle(visualPage, "live_event", "Live Event", 33, function(v) if v then Game.EventLog.enable() else Game.EventLog.disable() end end)
end

do
    local playersPage = pages["Players"]
    addSectionHeader(playersPage, "SURVIVOR", 0)
    addToggle(playersPage, "infinite_stamina", "Infinite Stamina", 10, function(v) if v then Game.InfiniteStamina.enable() else Game.InfiniteStamina.disable() end end)
    addToggle(playersPage, "anti_ragdoll", "Anti Ragdoll", 11, function(v) if v then Game.AntiRagdoll.enable() else Game.AntiRagdoll.disable() end end)
    addSectionHeader(playersPage, "JUMP", 20)
    addToggle(playersPage, "jump_enabled", "JumpPower", 21, function(v) Game.PlayerState.jumpEnabled = v; Game.applyPlayerState() end)
    addSlider(playersPage, "jump_value", "JumpPower Value", 50, 500, 22, function(v) Game.PlayerState.jumpPower = v; if Game.PlayerState.jumpEnabled then Game.applyPlayerState() end end)
    if Options["jump_value"] == nil then Options["jump_value"] = 50 end
    Game.PlayerState.jumpPower = Options["jump_value"] or 50
    Game.PlayerState.jumpEnabled = Options["jump_enabled"] == true
    addSectionHeader(playersPage, "SPEED", 30)
    addToggle(playersPage, "tpwalk_enabled", "Speed Power", 31, function(v) Game.PlayerState.speedPower = v end)
    addSlider(playersPage, "tp_speed", "Speed Power Value", 1, 50, 32, function(v) Game.PlayerState.tpSpeed = v end)
    if Options["tp_speed"] == nil then Options["tp_speed"] = 3 end
    Game.PlayerState.tpSpeed = Options["tp_speed"] or 3
    Game.PlayerState.speedPower = Options["tpwalk_enabled"] == true
    addSectionHeader(playersPage, "ESCAPE", 40)
    addToggle(playersPage, "auto_escape", "Auto Escape", 41, function(v)
        Game.Panic.setAuto(v)
        notify("Auto Escape", v and "Watching Hulk distance" or "Disabled", 2, v and "success" or "info")
    end)
    addClickButton(playersPage, "Escape Button", CLICK_ICON, 42, function()
        local ok = Game.Panic.fireManual()
        notify("Escape", ok and "Teleported" or "No safe spot / cooldown", 2, ok and "success" or "warn")
    end)
end

do
    local miscPage = pages["Misc"]
    addSectionHeader(miscPage, "AUTOMATION", 0)
    addToggle(miscPage, "auto_mission", "Auto Mission", 10, function(v) Game.AutoMission.setEnabled(v) end)
    addSectionHeader(miscPage, "ABILITY SPIN", 20)
    addToggle(miscPage, "spin_ability", "Spin Ability", 21, function(v) Game.SpinSystem.setEnabled(v) end)
    Game.addAbilityList(miscPage, 22)
    addSectionHeader(miscPage, "UTILITY", 40)
    addToggle(miscPage, "anti_debris", "Anti Debris", 41, function(v) if v then Game.AntiDebris.enable() else Game.AntiDebris.disable() end end)
    addToggle(miscPage, "remove_doors", "Remove Doors", 42, function(v) if v then Game.Doors.enable() else Game.Doors.disable() end end)
end

do
    local settingsPage = pages["Settings"]
    local current_config = tostring(Options.last_selected_config or "")
    local cfgDropdown
    local function refreshConfigs() return ConfigSys.list() end
    local function persistAutoload()
        if Options.auto_load_config and current_config ~= "" then
            ConfigSys.writeAutoload(true, current_config)
        else
            ConfigSys.writeAutoload(false, current_config)
        end
    end
    local function selectConfig(name)
        current_config = name or ""
        setOption("last_selected_config", current_config)
        if cfgDropdown then cfgDropdown.refresh() end
        if Options.auto_load_config then persistAutoload() end
    end
    local APPLY_ORDER = { "theme_color", "auto_load_config" }
    local function applyToUI(applied, cascade)
        local delay = 0
        for _, key in ipairs(APPLY_ORDER) do
            if applied[key] then
                local setter = Registry[key]
                local value = Options[key]
                if setter and value ~= nil then
                    if cascade then task.delay(delay, function() if alive then pcall(setter, value) end end); delay = delay + 0.08
                    else pcall(setter, value) end
                end
            end
        end
        for k, _ in pairs(applied) do
            if not k:match("^theme_color$") and not k:match("^auto_load_config$") then
                local setter = Registry[k]
                if setter and Options[k] ~= nil then
                    if cascade then task.delay(delay, function() if alive then pcall(setter, Options[k]) end end); delay = delay + 0.05
                    else pcall(setter, Options[k]) end
                end
            end
        end
    end
    Registry["theme_color"] = function(c) Theme.set(c) end
    addSectionHeader(settingsPage, "CONFIGURATION", 0)
    local nameBox = addTextBox(settingsPage, nil, "Config Name", 10, nil, "Enter preset name...")
    cfgDropdown = addDropdown(settingsPage, "Selected Config", 11, {
        header = "Configs",
        getOptions = refreshConfigs,
        get = function() return current_config end,
        set = function(name) selectConfig(name) end,
        empty = "No configs found",
    })
    addButtonRow(settingsPage, 12, {
        { text = "Create Config", callback = function()
            local name = ConfigSys.sanitize(nameBox.Text)
            if name == "" then notify("Config", "Enter a name first", 2, "error"); return end
            if not ConfigSys.canWrite() then notify("Config", "Executor has no file access", 2.5, "error"); return end
            if ConfigSys.exists(name) then notify("Config", "Already exists: " .. name, 2.5, "warn"); return end
            if ConfigSys.save(name, serializeOptions()) then
                nameBox.Text = ""
                notify("Config", "Created: " .. name, 2, "success")
                selectConfig(name)
            else notify("Config", "Failed to create", 2, "error") end
        end },
        { text = "Save Config", callback = function()
            if current_config ~= "" then
                if ConfigSys.save(current_config, serializeOptions()) then
                    notify("Config", "Saved: " .. current_config, 2, "success")
                else notify("Config", "Failed to save", 2, "error") end
            else notify("Config", "No config selected", 2, "error") end
        end },
    })
    addButtonRow(settingsPage, 13, {
        { text = "Load Config", callback = function()
            if current_config ~= "" then
                local data = ConfigSys.load(current_config)
                if data then
                    local applied = deserializeOptions(data)
                    applyToUI(applied, true)
                    notify("Config", "Loaded: " .. current_config, 2, "success")
                else notify("Config", "Failed to load", 2, "error") end
            else notify("Config", "No config selected", 2, "error") end
        end },
        { text = "Delete Config", hoverColor = C_ERROR, callback = function()
            if current_config == "" then notify("Config", "No config selected", 2, "error"); return end
            local target = current_config
            Confirm.ask("HE IS SURE?", "Delete: " .. target, function()
                if ConfigSys.delete(target) then
                    notify("Config", "Deleted: " .. target, 2, "success")
                    if current_config == target then selectConfig("") end
                else notify("Config", "Failed to delete", 2, "error") end
            end)
        end },
    })
    addButtonRow(settingsPage, 14, {
        { text = "Refresh Configs", callback = function()
            local configs = refreshConfigs()
            notify("Config", "Refreshed: " .. #configs .. " found.", 2, "info")
            local exists = false
            for _, name in ipairs(configs) do if name == current_config then exists = true; break end end
            if not exists and current_config ~= "" then selectConfig("") end
            cfgDropdown.refresh()
        end },
    })
    addSectionHeader(settingsPage, "AUTOMATION", 20)
    addToggle(settingsPage, "auto_load_config", "Auto Load Config", 21, function(state)
        persistAutoload()
        if state and current_config ~= "" then notify("Config", "Auto load on: " .. current_config, 2, "success")
        elseif state then notify("Config", "Auto load ON (select a config)", 2, "warn") end
    end)
    do
        local al = ConfigSys.readAutoload()
        if al and al.enabled == true and type(al.config) == "string" and al.config ~= "" then
            setOption("auto_load_config", true)
            setOption("last_selected_config", al.config)
            current_config = al.config
            cfgDropdown.refresh()
        end
    end
end

local tabButtons, activeTab = {}, nil
local entranceToken = 0
local function tabY(i) return TAB_TOP + (i - 1) * (TAB_H + TAB_GAP) end

local function renderTab(name, animate)
    local data = tabButtons[name]; if not data then return end
    local c = Theme.c; local d = animate and 0.22 or 0
    local active = activeTab == name
    local col = active and c.textActive or (data.hover and TEXT or TEXT_DIM)
    apply(data.icon, { ImageColor3 = col, Size = active and UDim2.fromOffset(20, 20) or UDim2.fromOffset(18, 18), Position = active and UDim2.new(0, 11, 0.5, -10) or UDim2.new(0, 12, 0.5, -9) }, d, Enum.EasingStyle.Back)
    apply(data.label, { TextColor3 = col }, d)
end

local function playEntrance(page)
    entranceToken = entranceToken + 1
    local my = entranceToken
    contentGroup.GroupTransparency = 0.65
    tween(contentGroup, { GroupTransparency = 0 }, 0.28, Enum.EasingStyle.Quad)
    local wraps = {}
    for _, ch in ipairs(page:GetChildren()) do
        if ch:IsA("Frame") and ch:GetAttribute("Entrance") then wraps[#wraps + 1] = ch end
    end
    table.sort(wraps, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    for i, w in ipairs(wraps) do
        local card = w:FindFirstChild("Card")
        if card then
            card.Position = UDim2.new(0, 18, 0, 0)
            task.delay((i - 1) * 0.04, function()
                if entranceToken == my and card.Parent then tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.4, Enum.EasingStyle.Quint) end
            end)
        end
    end
end

local function selectTab(name, silent, force)
    if activeTab == name and not force then return end
    local prev = activeTab
    activeTab = name
    Popup.close(); Tooltip.hide()
    local idx = tabButtons[name].index
    tween(tabIndicator, { Position = UDim2.fromOffset(8, tabY(idx)) }, silent and 0 or 0.32, Enum.EasingStyle.Quint)
    if prev then renderTab(prev, true) end
    renderTab(name, true)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    pages[name].CanvasPosition = Vector2.new(0, 0)
    playEntrance(pages[name])
end

for i, tab in ipairs(TABS) do
    local btn = new("TextButton", { Size = UDim2.fromOffset(tabW, TAB_H), Position = UDim2.fromOffset(8, tabY(i)), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = sidebar })
    local icon = new("ImageLabel", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 12, 0.5, -9), BackgroundTransparency = 1, Image = tab.icon, ImageColor3 = TEXT_DIM, ZIndex = 4, Parent = btn })
    local label = newLabel(btn, tab.name, 12, FONT_MAIN, TEXT_DIM, { Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 40, 0, 0), ZIndex = 4 })
    local data = { btn = btn, icon = icon, label = label, index = i, hover = false }
    tabButtons[tab.name] = data
    btn.MouseEnter:Connect(function() data.hover = true renderTab(tab.name, true) end)
    btn.MouseLeave:Connect(function() data.hover = false renderTab(tab.name, true) end)
    btn.MouseButton1Click:Connect(function() selectTab(tab.name) end)
end
Theme.reg(sidebar, function(_, a) for n in pairs(tabButtons) do renderTab(n, a) end end)

local posX, posY, tgtX, tgtY = 0, 0, 0, 0
local dragging, dragOrigin, startX, startY = false, nil, 0, 0
local isMin, isAnim = false, false
local resizing = false

local function clampPos(x, y)
    local vp = viewport()
    local sc = fitScale.Scale
    local halfW = winW * sc / 2
    local halfH = winH * sc / 2
    return math.clamp(x, -(vp.X / 2 - halfW + 20), vp.X / 2 - halfW + 20),
           math.clamp(y, -(vp.Y / 2 - halfH + 20), vp.Y / 2 - halfH + 20)
end

grip.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if isAnim or isMin or resizing then return end
    Popup.close(); Tooltip.hide()
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    local startP = isTouch and input.Position or UserInputService:GetMouseLocation()
    local vp = viewport()
    local startWinW, startWinH = winW, winH
    local startScale = fitScale.Scale
    local topLeftX = vp.X / 2 + posX - startWinW * startScale / 2
    local topLeftY = vp.Y / 2 + posY - startWinH * startScale / 2
    resizing = true
    local c1, c2, done = nil, nil, false
    local function finish() if done then return end; done = true; resizing = false; if c1 then c1:Disconnect() end; if c2 then c2:Disconnect() end end
    c1 = UserInputService.InputChanged:Connect(function(i)
        local ok = (isTouch and i.UserInputType == Enum.UserInputType.Touch) or (not isTouch and i.UserInputType == Enum.UserInputType.MouseMovement)
        if not ok then return end
        local p = isTouch and i.Position or UserInputService:GetMouseLocation()
        local d = p - startP
        local targetAbsW = math.clamp(startWinW * startScale + d.X, MIN_W * startScale, MAX_W * startScale)
        local targetAbsH = math.clamp(startWinH * startScale + d.Y, MIN_H * startScale, MAX_H * startScale)
        local curScale = fitScale.Scale
        winW = math.clamp(targetAbsW / curScale, MIN_W, MAX_W)
        winH = math.clamp(targetAbsH / curScale, MIN_H, MAX_H)
        root.Size = UDim2.fromOffset(winW, winH)
        updateFit()
        local finalScale = fitScale.Scale
        local newCX = topLeftX + (winW * finalScale) / 2
        local newCY = topLeftY + (winH * finalScale) / 2
        posX, posY = newCX - vp.X / 2, newCY - vp.Y / 2
        tgtX, tgtY = posX, posY
        root.Position = UDim2.new(0.5, posX, 0.5, posY)
    end)
    c2 = UserInputService.InputEnded:Connect(function(i)
        local ok = (isTouch and i.UserInputType == Enum.UserInputType.Touch) or (not isTouch and i.UserInputType == Enum.UserInputType.MouseButton1)
        if ok then finish() end
    end)
end)

dragCatcher.InputBegan:Connect(function(input)
    if isAnim or isMin or resizing then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragOrigin = input.Position; startX, startY = tgtX, tgtY
        Popup.close(); Tooltip.hide()
    end
end)
bind(UserInputService.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - dragOrigin
        tgtX, tgtY = clampPos(startX + d.X, startY + d.Y)
    end
end)
bind(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local premiumClock = 0
bind(RunService.RenderStepped, function(dt)
    if not resizing and (posX ~= tgtX or posY ~= tgtY) then
        local k = math.min(1, dt * 22)
        posX = posX + (tgtX - posX) * k
        posY = posY + (tgtY - posY) * k
        if math.abs(tgtX - posX) < 0.25 then posX = tgtX end
        if math.abs(tgtY - posY) < 0.25 then posY = tgtY end
        if not (isAnim or isMin) then root.Position = UDim2.new(0.5, posX, 0.5, posY) end
    end
    premiumClock = premiumClock + dt
    premiumGrad.Offset = Vector2.new(-1 + ((premiumClock * 0.45) % 2.4) - 0.2, 0)
end)

local ballHolder
local ballPos = Vector2.new(16, 16)
local savedBallPos = ballPos

local function clampBall(p)
    local vp = viewport()
    return Vector2.new(math.clamp(p.X, 6, vp.X - BALL - 6), math.clamp(p.Y, 6, vp.Y - BALL - 6))
end

local restore

local function createBall()
    ballPos = clampBall(ballPos)
    ballHolder = new("Frame", { Name = "BallHolder", Size = UDim2.fromOffset(BALL, BALL), Position = UDim2.fromOffset(ballPos.X, ballPos.Y), BackgroundTransparency = 1, ZIndex = 300, Parent = gui })
    local hScale = new("UIScale", { Scale = 0, Parent = ballHolder })
    local pulse = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(BALL, BALL), BackgroundTransparency = 1, ZIndex = 298, Parent = ballHolder })
    corner(pulse, 16)
    local pulseStroke = stroke(pulse, Theme.c.accent, 2, 1)
    local ball = new("TextButton", { Size = UDim2.fromOffset(BALL, BALL), BackgroundColor3 = BLACK, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, ZIndex = 300, Parent = ballHolder })
    corner(ball, 16)
    local ballStroke = stroke(ball, Theme.c.accent, 1.5, 0.4)
    new("ImageLabel", { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0.5, -20), BackgroundTransparency = 1, Image = LOGO_BALL_ICON, ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 305, Parent = ball })
    tween(hScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    task.spawn(function()
        while alive and ballHolder and pulse.Parent do
            pulse.Size = UDim2.fromOffset(BALL, BALL); pulseStroke.Transparency = 0.5
            tween(pulse, { Size = UDim2.fromOffset(BALL + 26, BALL + 26) }, 1.6, Enum.EasingStyle.Quad)
            tween(pulseStroke, { Transparency = 1 }, 1.6, Enum.EasingStyle.Quad)
            task.wait(2.4)
        end
    end)
    ball.MouseEnter:Connect(function()
        tween(ball, { BackgroundColor3 = Color3.fromRGB(22, 22, 28) }, 0.15)
        tween(ballStroke, { Transparency = 0 }, 0.15)
        tween(hScale, { Scale = 1.07 }, 0.15, Enum.EasingStyle.Back)
    end)
    ball.MouseLeave:Connect(function()
        tween(ball, { BackgroundColor3 = BLACK }, 0.15)
        tween(ballStroke, { Transparency = 0.4 }, 0.15)
        tween(hScale, { Scale = 1 }, 0.15)
    end)
    local bDrag, moved, bStart, bOrigin = false, false, nil, nil
    ball.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bDrag, moved = true, false; bStart = input.Position; bOrigin = ballPos
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if bDrag and ballHolder and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - bStart
            if math.abs(d.X) > 8 or math.abs(d.Y) > 8 then moved = true end
            if moved then
                ballPos = clampBall(Vector2.new(bOrigin.X + d.X, bOrigin.Y + d.Y))
                ballHolder.Position = UDim2.fromOffset(ballPos.X, ballPos.Y)
            end
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if bDrag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            bDrag = false
            if moved and ballHolder then
                local vp = viewport()
                local snapX = (ballPos.X + BALL / 2 < vp.X / 2) and 10 or (vp.X - BALL - 10)
                ballPos = clampBall(Vector2.new(snapX, ballPos.Y))
                tween(ballHolder, { Position = UDim2.fromOffset(ballPos.X, ballPos.Y) }, 0.3, Enum.EasingStyle.Back)
                savedBallPos = ballPos
            elseif not moved then restore() end
        end
    end)
end

local function minimize()
    if isAnim or isMin then return end
    isAnim = true; Popup.close(); Tooltip.hide()
    local cx, cy = ballPos.X + BALL / 2, ballPos.Y + BALL / 2
    tween(canvas, { GroupTransparency = 1 }, 0.24)
    tween(popScale, { Scale = 0.35 }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(root, { Position = UDim2.fromOffset(cx, cy) }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    setShadow(false, 0.2)
    task.wait(0.3)
    root.Visible = false
    createBall()
    isMin = true; isAnim = false
end

restore = function()
    if isAnim or not isMin then return end
    isAnim = true
    local lx, ly = ballPos.X + BALL / 2, ballPos.Y + BALL / 2
    savedBallPos = ballPos
    local holder = ballHolder; ballHolder = nil
    if holder then
        local sc = holder:FindFirstChildOfClass("UIScale")
        if sc then tween(sc, { Scale = 0 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
        Debris:AddItem(holder, 0.22)
    end
    task.wait(0.18)
    root.Visible = true
    root.Position = UDim2.fromOffset(lx, ly)
    canvas.GroupTransparency = 1; popScale.Scale = 0.35
    tween(root, { Position = UDim2.new(0.5, posX, 0.5, posY) }, 0.45, Enum.EasingStyle.Back)
    tween(popScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    tween(canvas, { GroupTransparency = 0 }, 0.3)
    setShadow(true, 0.4)
    task.delay(0.46, function() isMin = false; isAnim = false end)
end

minimizeBtn.MouseButton1Click:Connect(function() task.spawn(minimize) end)
bind(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if isMin then task.spawn(restore) else task.spawn(minimize) end
    end
end)

local function destroyAll()
    if not alive then return end
    alive = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("BabisAntiRagdoll") end)
    pcall(function() gui:Destroy() end)
    Confirm.destroy()
    task.delay(6, Notifier.destroy)
    genv.BabisUnload = nil
    genv.BabisSetTheme = nil
end
genv.BabisUnload = destroyAll
genv.BabisSetTheme = function(c) Theme.set(c) end

local function closeWindow()
    if not alive then return end
    Popup.close()
    if isMin then destroyAll(); return end
    tween(canvas, { GroupTransparency = 1 }, 0.25)
    tween(popScale, { Scale = 0.88 }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    setShadow(false, 0.2)
    task.delay(0.3, destroyAll)
end
local function askClose()
    if Confirm then Confirm.ask("HE IS SURE?", "", closeWindow) else closeWindow() end
end
closeBtnHeader.MouseButton1Click:Connect(function() askClose() end)

local floatClose = new("TextButton", { Name = "FloatClose", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -54, 0, 12), BackgroundColor3 = Theme.c.bgMain, Text = "✕", TextColor3 = TEXT, TextSize = 18, Font = FONT_STRONG, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 400, Parent = gui })
corner(floatClose, 20)
local fcStroke = stroke(floatClose, Theme.c.border, 1, 0.1)
Theme.bind(floatClose, "BackgroundColor3", "bgMain"); Theme.bind(fcStroke, "Color", "border")
floatClose.MouseEnter:Connect(function() tween(floatClose, { BackgroundColor3 = C_ERROR:Lerp(BLACK, 0.55), TextColor3 = WHITE }, 0.15); tween(fcStroke, { Color = C_ERROR }, 0.15) end)
floatClose.MouseLeave:Connect(function() tween(floatClose, { BackgroundColor3 = Theme.c.bgMain, TextColor3 = TEXT }, 0.18); tween(fcStroke, { Color = Theme.c.border }, 0.18) end)
floatClose.MouseButton1Click:Connect(function() askClose() end)

if typeof(Options.theme_color) == "Color3" and not colorMatch(Options.theme_color, ORIGINAL_THEME.accent, 0.004) then
    Theme.set(Options.theme_color)
end

selectTab("Main", true, true)
for i, tab in ipairs(TABS) do
    local b = tabButtons[tab.name].btn
    b.Position = UDim2.fromOffset(-24, tabY(i))
    task.delay(0.15 + i * 0.05, function() if b.Parent then tween(b, { Position = UDim2.fromOffset(8, tabY(i)) }, 0.45, Enum.EasingStyle.Back) end end)
end
root.Rotation = -4
task.delay(0.12, function()
    if not alive then return end
    tween(canvas, { GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Quad)
    tween(popScale, { Scale = 1 }, 0.6, Enum.EasingStyle.Back)
    tween(root, { Rotation = 0 }, 0.6, Enum.EasingStyle.Back)
    setShadow(true, 0.6)
end)

for _, k in ipairs(PERSIST_KEYS) do
    if Options[k] ~= nil and Registry[k] then pcall(Registry[k], Options[k]) end
end

print("[Babis] ready")
return true
