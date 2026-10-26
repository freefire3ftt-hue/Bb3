--[[ ============================================================
     ardv2.lua
     Library (Halloween UI) + Hulk options (Settings only)
     Cole o `local Game = (function() ... end)()` do v2.8 no
     marker [PASTE GAME BACKEND AQUI].
     ============================================================ ]]

-- ╔══════════════════════════════════════════════════════════╗
-- ║ PART 1 — LIBRARY                                         ║
-- ╚══════════════════════════════════════════════════════════╝
local Library = (function()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local Workspace        = game:GetService("Workspace")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local genv = (function()
    local ok, g = pcall(function() return getgenv() end)
    return ok and type(g) == "table" and g or _G
end)()

local uiParent = PG
pcall(function() if gethui then local h = gethui(); if h then uiParent = h end end end)

for _, holder in ipairs({ uiParent, PG }) do
    for _, n in ipairs({ "BabisUIKitNotif", "MeuRetangulo", "BabisConfirmDialog" }) do
        local o = holder:FindFirstChild(n); if o then o:Destroy() end
    end
end

local FONT_MAIN   = Enum.Font.GothamBold
local FONT_STRONG = Enum.Font.GothamBlack
local FONT_CODE   = Enum.Font.Code

local LOGO_ICON        = "rbxassetid://88981628950457"
local LOGO_BALL_ICON   = "rbxassetid://78039301847826"
local BELL_ICON        = "rbxassetid://7072706001"
local ARROW_ICON       = "rbxassetid://7734034764"
local MIN_ICON         = "rbxassetid://7734000129"
local CLOSE_ICON       = "rbxassetid://7743878857"
local DISCORD_ICON     = "rbxassetid://100770414662869"
local DISCORD_TINT     = Color3.fromRGB(115, 136, 217)
local DISCORD_URL      = "https://discord.gg/ZvCwj68e"
local CHECK_ICON       = "rbxassetid://111774854328409"

local DESIGN_W, DESIGN_H = 720, 470
local HEADER_H   = 60
local SIDEBAR_W  = 140
local CORNER     = 20
local CARD_H     = 42
local BALL       = 62

local winW, winH = DESIGN_W, DESIGN_H
local MIN_W, MIN_H = 500, 380
local MAX_W, MAX_H = DESIGN_W * 2, DESIGN_H * 2

local TEXT       = Color3.fromRGB(240, 232, 242)
local TEXT_DIM   = Color3.fromRGB(165, 148, 180)
local TEXT_MUTED = Color3.fromRGB(128, 112, 144)
local WHITE      = Color3.new(1, 1, 1)
local BLACK      = Color3.new(0, 0, 0)
local C_SUCCESS  = Color3.fromRGB(120, 235, 80)
local C_ERROR    = Color3.fromRGB(235, 70, 70)
local C_WARN     = Color3.fromRGB(255, 175, 45)
local HW_PURPLE  = Color3.fromRGB(150, 70, 235)
local HW_SPIDER  = "\u{1F577}\u{FE0F}"
local HW_PUMPKIN = "\u{1F383}"

local alive = true
local conns = {}
local function bind(sig, fn) local c = sig:Connect(fn); conns[#conns+1] = c; return c end

local function new(cls, props)
    local o = Instance.new(cls); local p
    if props then for k, v in pairs(props) do if k == "Parent" then p = v else o[k] = v end end end
    if p then o.Parent = p end
    return o
end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = p }) end
local function stroke(p, col, th, tr)
    return new("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
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
    local l = new("TextLabel", { BackgroundTransparency = 1, Text = text, TextSize = size, Font = font,
        TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = parent })
    if props then for k, v in pairs(props) do l[k] = v end end
    return l
end

local function hsvToRgb(h, s, v)
    h = h % 360; local c = v * s; local x = c * (1 - math.abs((h/60) % 2 - 1)); local m = v - c
    local r, g, b
    if h < 60 then r, g, b = c, x, 0 elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c else r, g, b = c, 0, x end
    return Color3.new(r + m, g + m, b + m)
end
local function rgbToHsv(c)
    local r, g, b = c.R, c.G, c.B; local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn; local h = 0
    if d > 0 then
        if mx == r then h = 60 * (((g - b) / d) % 6)
        elseif mx == g then h = 60 * ((b - r) / d + 2)
        else h = 60 * ((r - g) / d + 4) end
    end
    return h, (mx > 0 and (d / mx) or 0), mx
end
local function toHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end

local function derive(t)
    t.hover = t.bgCard:Lerp(WHITE, 0.035); t.trackOff = t.bgCard:Lerp(WHITE, 0.08); return t
end

local ORIGINAL_THEME = derive({
    accent = Color3.fromRGB(255, 112, 22), glow = Color3.fromRGB(255, 196, 96),
    border = Color3.fromRGB(54, 34, 70),   textActive = Color3.fromRGB(255, 130, 40),
    bgMain = Color3.fromRGB(10, 6, 16),    bgHeader = Color3.fromRGB(17, 10, 26),
    bgCard = Color3.fromRGB(19, 11, 29),
})

local function makeTheme(base)
    local glow = Color3.new(math.min(1, base.R*0.5+0.5), math.min(1, base.G*0.5+0.5), math.min(1, base.B*0.5+0.5))
    local border = Color3.new(math.clamp(base.R*0.3+0.05,0,1), math.clamp(base.G*0.3+0.05,0,1), math.clamp(base.B*0.3+0.05,0,1))
    local br = base.R*0.299 + base.G*0.587 + base.B*0.114
    return derive({
        accent = base, glow = glow, border = border, textActive = br > 0.4 and base or glow,
        bgMain = Color3.new(0.03+base.R*0.05, 0.03+base.G*0.05, 0.04+base.B*0.05),
        bgHeader = Color3.new(0.04+base.R*0.06, 0.04+base.G*0.06, 0.05+base.B*0.06),
        bgCard = Color3.new(0.04+base.R*0.06, 0.04+base.G*0.06, 0.05+base.B*0.06),
    })
end
local function colorMatch(a, b, tol)
    tol = tol or 0.02
    return math.abs(a.R-b.R) < tol and math.abs(a.G-b.G) < tol and math.abs(a.B-b.B) < tol
end

local Theme = { c = ORIGINAL_THEME, regs = {} }
function Theme.reg(inst, fn)
    Theme.regs[#Theme.regs+1] = { inst = inst, fn = fn }; fn(Theme.c, false)
end
function Theme.bind(inst, prop, role)
    Theme.reg(inst, function(c, a)
        if a then tween(inst, { [prop] = c[role] }, 0.35, Enum.EasingStyle.Quad)
        else inst[prop] = c[role] end
    end)
end

local setOption
function Theme.set(color)
    if typeof(color) ~= "Color3" then return end
    local newT = colorMatch(color, ORIGINAL_THEME.accent, 0.004) and ORIGINAL_THEME or makeTheme(color)
    Theme.c = newT
    if setOption then setOption("theme_color", newT.accent) end
    for i = #Theme.regs, 1, -1 do
        local r = Theme.regs[i]
        if r.inst and not r.inst.Parent then table.remove(Theme.regs, i)
        else pcall(r.fn, newT, true) end
    end
end

genv.BabisESPColor = genv.BabisESPColor or Color3.fromRGB(230, 30, 30)

local DEFAULTS = {
    theme_color = ORIGINAL_THEME.accent, auto_load_config = false,
    last_selected_config = "", esp_color = genv.BabisESPColor,
}
genv.BabisOptions = genv.BabisOptions or {}
local Options = genv.BabisOptions
for k, v in pairs(DEFAULTS) do if Options[k] == nil then Options[k] = v end end
if typeof(Options.esp_color) ~= "Color3" then Options.esp_color = DEFAULTS.esp_color end
if typeof(Options.theme_color) ~= "Color3" then Options.theme_color = DEFAULTS.theme_color end

local ChangedEvent = Instance.new("BindableEvent")
setOption = function(k, v) Options[k] = v; pcall(function() ChangedEvent:Fire(k, v) end) end
local Registry = {}

local CFG = { root = "Babis", folder = "Babis/configs", ext = ".json", autoload = "Babis/autoload.txt" }
local ConfigSys = {}
function ConfigSys.canWrite() return type(writefile) == "function" and type(readfile) == "function" end
function ConfigSys.ensure()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
    pcall(function()
        if not isfolder(CFG.root) then makefolder(CFG.root) end
        if not isfolder(CFG.folder) then makefolder(CFG.folder) end
    end)
end
function ConfigSys.sanitize(name)
    name = tostring(name or ""):gsub("[%c\\/:*?\"<>|]",""); name = name:match("^%s*(.-)%s*$") or ""
    return name:sub(1,32)
end
function ConfigSys.list()
    ConfigSys.ensure(); local out = {}
    if type(listfiles) ~= "function" then return out end
    local ok, files = pcall(listfiles, CFG.folder)
    if not ok or type(files) ~= "table" then return out end
    for _, p in ipairs(files) do local n = tostring(p):match("([^/\\]+)%.json$"); if n then out[#out+1] = n end end
    table.sort(out); return out
end
function ConfigSys.exists(name)
    for _, n in ipairs(ConfigSys.list()) do if n:lower() == name:lower() then return true end end
    return false
end
function ConfigSys.save(name, data)
    if not ConfigSys.canWrite() then return false end
    ConfigSys.ensure()
    if type(name) ~= "string" or name == "" then return false end
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    return pcall(writefile, CFG.folder .. "/" .. name .. CFG.ext, enc)
end
function ConfigSys.load(name)
    if type(readfile) ~= "function" then return nil end
    local ok, content = pcall(readfile, CFG.folder .. "/" .. name .. CFG.ext)
    if not ok or type(content) ~= "string" then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return nil end
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
end

local PERSIST_KEYS = { "theme_color", "auto_load_config", "last_selected_config", "esp_color" }

local function parseColor(v)
    if type(v) == "table" and type(v.R) == "number" and type(v.G) == "number" and type(v.B) == "number" then
        return Color3.new(math.clamp(v.R,0,1), math.clamp(v.G,0,1), math.clamp(v.B,0,1))
    end
end
local function serializeOptions()
    local safe = {}
    for _, k in ipairs(PERSIST_KEYS) do
        local v = Options[k]
        if typeof(v) == "Color3" then safe[k] = { R=v.R, G=v.G, B=v.B } else safe[k] = v end
    end
    return safe
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
    local ng = new("ScreenGui", { Name = "BabisUIKitNotif", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 300, Parent = uiParent })
    local container = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, NOTIF_W, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16), Parent = ng })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = container })
    local order, active = 0, {}
    local KIND = { success = C_SUCCESS, error = C_ERROR, warn = C_WARN }

    local function dismiss(row)
        if not row or not row.Parent or row:GetAttribute("Dismissing") then return end
        row:SetAttribute("Dismissing", true)
        local card = row:FindFirstChild("Card")
        if card then tween(card, { Position = UDim2.new(1, NOTIF_W+40, 0, 0), GroupTransparency = 1 }, 0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
        task.delay(0.2, function() if row and row.Parent then tween(row, { Size = UDim2.new(1,0,0,0) }, 0.22) end end)
        task.delay(0.5, function() if row and row.Parent then row:Destroy() end end)
    end

    function Notifier.notify(title, message, duration, kind)
        title = tostring(title or "Notification"); message = tostring(message or ""); duration = tonumber(duration) or 2.5
        order = order + 1
        local col = KIND[kind or "info"] or Theme.c.accent
        local textW = NOTIF_W - 78; local msgH = 14
        pcall(function() msgH = TextService:GetTextSize(message, 11, FONT_MAIN, Vector2.new(textW, 1000)).Y end)
        local height = math.max(58, 14 + 18 + msgH + 16)
        local row = new("Frame", { Name = "Row", Size = UDim2.new(1,0,0,height), BackgroundTransparency = 1, LayoutOrder = order, Parent = container })
        local card = new("CanvasGroup", { Name = "Card", Size = UDim2.new(1,0,1,0), Position = UDim2.new(1, NOTIF_W+40, 0, 0),
            BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, GroupTransparency = 0.4, Parent = row })
        corner(card, 12)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(208,208,214)), Parent = card })
        local bf = new("Frame", { Size = UDim2.new(1,-2,1,-2), Position = UDim2.new(0,1,0,1), BackgroundTransparency = 1, ZIndex = 10, Parent = card })
        corner(bf, 11); stroke(bf, Theme.c.border, 1, 0.05)
        local bar = new("Frame", { Size = UDim2.new(0,4,1,-20), Position = UDim2.new(0,8,0,10), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(bar, 2)
        local iconBg = new("Frame", { Size = UDim2.new(0,32,0,32), Position = UDim2.new(0,20,0.5,-16), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(iconBg, 16); stroke(iconBg, col, 1, 0.35)
        new("ImageLabel", { Size = UDim2.new(0,18,0,18), Position = UDim2.new(0.5,-9,0.5,-9), BackgroundTransparency = 1,
            Image = BELL_ICON, ImageColor3 = col:Lerp(WHITE,0.35), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = iconBg })
        newLabel(card, title, 13, FONT_MAIN, TEXT, { Size = UDim2.new(1,-78,0,18), Position = UDim2.new(0,62,0,10), TextTruncate = Enum.TextTruncate.AtEnd })
        newLabel(card, message, 11, FONT_MAIN, TEXT_DIM, { Size = UDim2.new(1,-78,0,msgH), Position = UDim2.new(0,62,0,29), TextWrapped = true })
        local progBg = new("Frame", { Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2), BackgroundColor3 = Theme.c.border, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        local prog = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 4, Parent = progBg })
        local hit = new("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20, Parent = card })
        local hovering = false
        hit.MouseEnter:Connect(function() hovering = true end)
        hit.MouseLeave:Connect(function() hovering = false end)
        hit.MouseButton1Click:Connect(function() dismiss(row) end)
        for i = #active, 1, -1 do if not active[i].Parent then table.remove(active, i) end end
        active[#active+1] = row
        while #active > 5 do dismiss(active[1]); table.remove(active, 1) end
        tween(card, { Position = UDim2.new(0,0,0,0), GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
        task.spawn(function()
            local rem, last = duration, os.clock()
            while rem > 0 and row.Parent and not row:GetAttribute("Dismissing") do
                task.wait(0.03); local now = os.clock(); local dt = now - last; last = now
                if not hovering then rem = rem - dt end
                if prog.Parent then prog.Size = UDim2.new(math.max(0, rem/duration), 0, 1, 0) end
            end
            dismiss(row)
        end)
    end
    function Notifier.destroy() pcall(function() ng:Destroy() end) end
end
local function notify(t, m, d, k) Notifier.notify(t, m, d, k) end

local Confirm = {}
do
    local cg = new("ScreenGui", { Name = "BabisConfirmDialog", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 900, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PG })
    local dim = new("TextButton", { Size = UDim2.fromScale(1,1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Parent = cg })
    local panel = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(250,150), BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Parent = cg })
    corner(panel, 14)
    local pScale = new("UIScale", { Scale = 0.85, Parent = panel })
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205,205,212)), Parent = panel })
    local pb = new("Frame", { Size = UDim2.new(1,-2,1,-2), Position = UDim2.new(0,1,0,1), BackgroundTransparency = 1, ZIndex = 10, Parent = panel })
    corner(pb, 13); stroke(pb, Theme.c.border, 1.2, 0)
    local q = newLabel(panel, "ARE YOU SURE?", 19, FONT_STRONG, TEXT, { Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,22), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2 })
    local sub = newLabel(panel, "", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1,-24,0,16), Position = UDim2.new(0,12,0,52), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2 })
    local row = new("Frame", { AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,1,-16), Size = UDim2.fromOffset(176,40), BackgroundTransparency = 1, ZIndex = 3, Parent = panel })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
    local function mkBtn(t, s, c, ord)
        local b = new("TextButton", { LayoutOrder = ord, Size = UDim2.fromOffset(82,40), BackgroundColor3 = Theme.c.bgMain,
            Text = t, Font = FONT_STRONG, TextSize = s, TextColor3 = c, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = row })
        corner(b, 10); local st = stroke(b, Theme.c.border, 1, 0)
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.c.hover }, 0.12); tween(st, { Color = c }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.c.bgMain }, 0.15); tween(st, { Color = Theme.c.border }, 0.15) end)
        return b
    end
    local noB = mkBtn("✕", 18, C_ERROR, 1); local yesB = mkBtn("✓", 22, Theme.c.accent, 2)
    local isOpen, onYes, onNo, token = false, nil, nil, 0
    local function hide()
        if not isOpen then return end
        isOpen = false; token = token + 1
        tween(dim, { BackgroundTransparency = 1 }, 0.18); tween(panel, { GroupTransparency = 1 }, 0.16)
        tween(pScale, { Scale = 0.88 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local my = token
        task.delay(0.2, function() if token == my and cg.Parent then dim.Visible = false; panel.Visible = false end end)
    end
    function Confirm.ask(text, s, yfn, nfn)
        onYes, onNo = yfn, nfn; q.Text = text or "ARE YOU SURE?"; sub.Text = s or ""
        isOpen = true; token = token + 1
        dim.Visible = true; panel.Visible = true
        dim.BackgroundTransparency = 1; panel.GroupTransparency = 1; pScale.Scale = 0.85
        tween(dim, { BackgroundTransparency = 0.5 }, 0.25); tween(panel, { GroupTransparency = 0 }, 0.2)
        tween(pScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
    end
    noB.MouseButton1Click:Connect(function() local f = onNo; hide(); if f then f() end end)
    yesB.MouseButton1Click:Connect(function() local f = onYes; hide(); if f then task.delay(0.12, f) end end)
    dim.MouseButton1Click:Connect(function() noB.MouseButton1Click:Fire() end)
    bind(UserInputService.InputBegan, function(input)
        if not isOpen then return end
        if input.KeyCode == Enum.KeyCode.Escape then local f = onNo; hide(); if f then f() end
        elseif input.KeyCode == Enum.KeyCode.Return then local f = onYes; hide(); if f then task.delay(0.12, f) end end
    end)
    function Confirm.destroy() pcall(function() cg:Destroy() end) end
end

local function newWindow(opts)
    opts = opts or {}
    local SUBTITLE = opts.subtitle or "Your Game Name"
    local PREMIUM  = opts.premium or "Halloween Edition"

    local gui = new("ScreenGui", { Name = "MeuRetangulo", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PG })
    local root = new("Frame", { Name = "Root", AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(winW, winH), BackgroundTransparency = 1, Parent = gui })
    local fitScale = new("UIScale", { Parent = root })

    local function viewport()
        local s = gui.AbsoluteSize
        if s.X >= 50 and s.Y >= 50 then return s end
        local cam = Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1280,720)
    end
    local function updateFit()
        local vp = viewport()
        fitScale.Scale = math.clamp(math.min(vp.X*0.92/winW, vp.Y*0.90/winH), 0.5, 1.25)
    end
    updateFit()
    bind(gui:GetPropertyChangedSignal("AbsoluteSize"), updateFit)

    local shadowLayers = {}
    for i = 1, 7 do
        local s = new("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,8),
            Size = UDim2.new(1, i*7, 1, i*7), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Parent = root })
        corner(s, CORNER + i*3); shadowLayers[i] = s
    end
    local function setShadow(visible, d)
        for i, s in ipairs(shadowLayers) do
            apply(s, { BackgroundTransparency = visible and (0.9 + i*0.0075) or 1 }, d or 0.4, Enum.EasingStyle.Quad)
        end
    end

    local canvas = new("CanvasGroup", { Name = "Canvas", AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromScale(1,1), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 1, Parent = root })
    corner(canvas, CORNER); Theme.bind(canvas, "BackgroundColor3", "bgMain")
    local popScale = new("UIScale", { Scale = 0.86, Parent = canvas })
    new("UIGradient", { Rotation = 135, Color = ColorSequence.new(WHITE, Color3.fromRGB(208,208,218)), Parent = canvas })

    local borderFrame = new("Frame", { Name = "Border", Size = UDim2.new(1,-2,1,-2), Position = UDim2.new(0,1,0,1), BackgroundTransparency = 1, ZIndex = 60, Parent = canvas })
    corner(borderFrame, CORNER - 1)
    local borderStroke = stroke(borderFrame, Theme.c.border, 1.2, 0.05)
    Theme.bind(borderStroke, "Color", "border")

    local overlay = new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ZIndex = 100, Parent = canvas })

    -- Grip resize
    local grip = new("TextButton", { Size = UDim2.fromOffset(22,22), AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-4,1,-4),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 65, Parent = canvas })
    local gripDots = {}
    for _, d in ipairs({ {14,14},{8,14},{14,8},{2,14},{8,8},{14,2} }) do
        local dot = new("Frame", { Size = UDim2.fromOffset(2,2), Position = UDim2.fromOffset(d[1],d[2]),
            BackgroundColor3 = TEXT_MUTED, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 66, Parent = grip })
        corner(dot, 1); gripDots[#gripDots+1] = dot
    end
    grip.MouseEnter:Connect(function() for _, d in ipairs(gripDots) do tween(d, { BackgroundColor3 = Theme.c.accent, BackgroundTransparency = 0 }, 0.12) end end)
    grip.MouseLeave:Connect(function() for _, d in ipairs(gripDots) do tween(d, { BackgroundColor3 = TEXT_MUTED, BackgroundTransparency = 0.3 }, 0.15) end end)

    -- Header
    local header = new("Frame", { Name = "Header", Size = UDim2.new(1,0,0,HEADER_H), BackgroundColor3 = Theme.c.bgHeader,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 4, Parent = canvas })
    Theme.bind(header, "BackgroundColor3", "bgHeader")
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(206,206,214)), Parent = header })
    local headerLine = new("Frame", { Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,0,HEADER_H-1),
        BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 5, Parent = canvas })
    Theme.bind(headerLine, "BackgroundColor3", "accent")
    local hlg = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,1) }),
        Offset = Vector2.new(-1,0), Parent = headerLine })
    TweenService:Create(hlg, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1,0) }):Play()
    local l2 = new("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,HEADER_H),
        BackgroundColor3 = HW_PURPLE, BorderSizePixel = 0, ZIndex = 5, Parent = canvas })
    local g2 = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0.15), NumberSequenceKeypoint.new(1,1) }),
        Offset = Vector2.new(1,0), Parent = l2 })
    TweenService:Create(g2, TweenInfo.new(3.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(-1,0) }):Play()

    local hContent = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 5, Parent = header })
    local logoImg = new("ImageLabel", { BackgroundTransparency = 1, Image = LOGO_ICON, ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 6, Parent = hContent })
    logoImg.Size = UDim2.new(0,155,0,74.7); logoImg.Rotation = 0.1; logoImg.Position = UDim2.new(0,-22,0,-3)

    local BTN_SIZE, SEP_W = 30, 1
    local BOX_W = BTN_SIZE*3 + SEP_W*2 + 6
    local BOX_H = BTN_SIZE + 6
    local pipe = new("Frame", { Size = UDim2.new(0,3,0,24), Position = UDim2.new(0,108,0.5,-12),
        BackgroundColor3 = Color3.fromRGB(84,62,104), BorderSizePixel = 0, ZIndex = 6, Parent = hContent })
    corner(pipe, 2)
    new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,0.8) }), Parent = pipe })

    local subtitleW = -(118 + BOX_W + 30)
    newLabel(hContent, SUBTITLE, 14, FONT_STRONG, TEXT, { Size = UDim2.new(1,subtitleW,0,18), Position = UDim2.new(0,118,0.5,-17), ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
    local premiumLbl = newLabel(hContent, PREMIUM, 11, FONT_STRONG, WHITE, { Size = UDim2.new(1,subtitleW,0,14), Position = UDim2.new(0,118,0.5,3), ZIndex = 6, TextTruncate = Enum.TextTruncate.AtEnd })
    local premiumGrad = new("UIGradient", { Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,120,24)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,220,120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,120,24)) }), Offset = Vector2.new(-1,0), Parent = premiumLbl })

    local btnBox = new("Frame", { Size = UDim2.new(0,BOX_W,0,BOX_H), Position = UDim2.new(1,-(BOX_W+14),0.5,-BOX_H/2),
        BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 8, Parent = hContent })
    corner(btnBox, 9)
    local btnBoxStroke = stroke(btnBox, Theme.c.border, 1, 0.1)
    Theme.bind(btnBox, "BackgroundColor3", "bgMain"); Theme.bind(btnBoxStroke, "Color", "border")

    local function makeIconBtn(image, order, size, tint, hoverColor)
        size = size or 16
        local b = new("TextButton", { Size = UDim2.new(0,BTN_SIZE,0,BTN_SIZE), Position = UDim2.new(0,3+(order-1)*(BTN_SIZE+SEP_W),0.5,-BTN_SIZE/2),
            BackgroundColor3 = hoverColor or WHITE, BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 9, Parent = btnBox })
        corner(b, 7)
        local img = new("ImageLabel", { Size = UDim2.new(0,size,0,size), Position = UDim2.new(0.5,-size/2,0.5,-size/2), BackgroundTransparency = 1,
            Image = image, ImageColor3 = tint or Color3.fromRGB(222,215,228), ZIndex = 10, Parent = b })
        b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = hoverColor and 0.7 or 0.88 }, 0.12); tween(img, { ImageColor3 = WHITE }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }, 0.15); tween(img, { ImageColor3 = tint or Color3.fromRGB(222,215,228) }, 0.15) end)
        return b, img
    end
    local discordBtn, discordIcon = makeIconBtn(DISCORD_ICON, 1, 22, DISCORD_TINT)
    local minimizeBtn = makeIconBtn(MIN_ICON, 2, 16)
    local closeBtnHeader = makeIconBtn(CLOSE_ICON, 3, 16, nil, C_ERROR)

    for i = 1, 2 do
        local sep = new("Frame", { Size = UDim2.new(0,SEP_W,0,BTN_SIZE-8), Position = UDim2.new(0,3+i*BTN_SIZE+(i-1)*SEP_W,0.5,-(BTN_SIZE-8)/2),
            BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 9, Parent = btnBox })
        Theme.bind(sep, "BackgroundColor3", "border")
    end
    local dragCatcher = new("TextButton", { Size = UDim2.new(1,-(BOX_W+28),1,0), BackgroundTransparency = 1, Text = "",
        BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 7, Parent = hContent })

    local discordBusy = false
    discordBtn.MouseButton1Click:Connect(function()
        if discordBusy then return end
        discordBusy = true
        pcall(function() setclipboard(DISCORD_URL) end)
        local os, op = discordIcon.Size, discordIcon.Position
        tween(discordIcon, { Rotation = 360, Size = UDim2.new(0,28,0,28), Position = UDim2.new(0.5,-14,0.5,-14) }, 0.45, Enum.EasingStyle.Back)
        local check = new("ImageLabel", { Size = UDim2.new(0,22,0,22), Position = UDim2.new(0.5,-11,0.5,-11), BackgroundTransparency = 1,
            Image = CHECK_ICON, ImageColor3 = C_SUCCESS, ImageTransparency = 1, Rotation = -90, ScaleType = Enum.ScaleType.Fit, ZIndex = 11, Parent = discordBtn })
        task.delay(0.25, function() if check.Parent then tween(check, { ImageTransparency = 0, Rotation = 0 }, 0.28, Enum.EasingStyle.Back) end end)
        task.delay(1.15, function() if check.Parent then tween(check, { ImageTransparency = 1 }, 0.2) end end)
        task.delay(1.4, function() if check.Parent then check:Destroy() end end)
        task.delay(1.2, function() if discordIcon.Parent then tween(discordIcon, { Rotation = 0, Size = os, Position = op }, 0.2) end end)
        notify("Discord", "Link copied!", 1.8, "success")
        task.delay(1.5, function() discordBusy = false end)
    end)

    -- Sidebar
    local sidebar = new("Frame", { Size = UDim2.new(0,SIDEBAR_W,1,-HEADER_H), Position = UDim2.new(0,0,0,HEADER_H),
        BackgroundColor3 = Theme.c.bgHeader, BorderSizePixel = 0, ZIndex = 3, Parent = canvas })
    Theme.bind(sidebar, "BackgroundColor3", "bgHeader")
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200,200,210)), Parent = sidebar })
    local sideDiv = new("Frame", { Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0),
        BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 4, Parent = sidebar })
    Theme.bind(sideDiv, "BackgroundColor3", "border")

    local profile = new("Frame", { Size = UDim2.new(0,SIDEBAR_W-18,0,48), Position = UDim2.new(0,8,1,-58),
        BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 2, Parent = sidebar })
    corner(profile, 10)
    local profSt = stroke(profile, Theme.c.border, 1, 0.25)
    Theme.bind(profile, "BackgroundColor3", "bgMain"); Theme.bind(profSt, "Color", "border")
    local avatar = new("ImageLabel", { Size = UDim2.fromOffset(32,32), Position = UDim2.new(0,8,0.5,-16),
        BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 3,
        Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", LP.UserId), Parent = profile })
    corner(avatar, 16)
    local avSt = stroke(avatar, Theme.c.accent, 1.5, 0.2); Theme.bind(avSt, "Color", "accent")
    local onlineDot = new("Frame", { Size = UDim2.fromOffset(9,9), Position = UDim2.new(0,33,0.5,7), BackgroundColor3 = C_SUCCESS, BorderSizePixel = 0, ZIndex = 5, Parent = profile })
    corner(onlineDot, 5)
    stroke(onlineDot, Theme.c.bgMain, 1.5, 0)
    newLabel(profile, LP.DisplayName ~= "" and LP.DisplayName or LP.Name, 12, FONT_MAIN, TEXT, { Size = UDim2.new(1,-52,0,16), Position = UDim2.new(0,48,0.5,-16), TextTruncate = Enum.TextTruncate.AtEnd })
    newLabel(profile, "@"..LP.Name, 10, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1,-52,0,14), Position = UDim2.new(0,48,0.5,1), TextTruncate = Enum.TextTruncate.AtEnd })

    -- Single "Settings" tab
    local tabIndicator = new("Frame", { Size = UDim2.fromOffset(SIDEBAR_W-18,38), Position = UDim2.fromOffset(8,12),
        BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 1, Parent = sidebar })
    corner(tabIndicator, 9)
    local indSt = stroke(tabIndicator, Theme.c.border, 1, 0.3)
    Theme.bind(tabIndicator, "BackgroundColor3", "bgMain"); Theme.bind(indSt, "Color", "accent")
    local indBar = new("Frame", { AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(0,3,0.55,0),
        BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 2, Parent = tabIndicator })
    corner(indBar, 2); Theme.bind(indBar, "BackgroundColor3", "accent")
    local tabBtn = new("TextButton", { Size = UDim2.fromOffset(SIDEBAR_W-18,38), Position = UDim2.fromOffset(8,12),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = sidebar })
    local tabIcon = new("ImageLabel", { Size = UDim2.fromOffset(20,20), Position = UDim2.new(0,11,0.5,-10),
        BackgroundTransparency = 1, Image = "rbxassetid://7734053495", ImageColor3 = Theme.c.textActive, ZIndex = 4, Parent = tabBtn })
    newLabel(tabBtn, "Settings", 12, FONT_MAIN, Theme.c.textActive, { Size = UDim2.new(1,-44,1,0), Position = UDim2.new(0,40,0,0), ZIndex = 4 })

    -- Content
    local contentGroup = new("CanvasGroup", { Size = UDim2.new(1,-SIDEBAR_W,1,-HEADER_H), Position = UDim2.new(0,SIDEBAR_W,0,HEADER_H),
        BackgroundTransparency = 1, GroupTransparency = 0, ZIndex = 2, Parent = canvas })

    local pageFrame = new("ScrollingFrame", { Name = "Settings", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.c.accent, ScrollBarImageTransparency = 0.45,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, ZIndex = 3, Parent = contentGroup })
    Theme.bind(pageFrame, "ScrollBarImageColor3", "accent")
    new("UIPadding", { PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,16), PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,16), Parent = pageFrame })
    new("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pageFrame })

    local function cardBase(parent, height, order, clickable)
        local wrap = new("Frame", { Name = "Wrap", Size = UDim2.new(1,0,0,height), BackgroundTransparency = 1, LayoutOrder = order or 0, Parent = parent })
        wrap:SetAttribute("Entrance", true)
        local props = { Name = "Card", Size = UDim2.new(1,0,1,0), BackgroundColor3 = Theme.c.bgCard, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrap }
        local card
        if clickable then props.AutoButtonColor = false; props.Text = ""; card = new("TextButton", props)
        else card = new("Frame", props) end
        corner(card, 10)
        local st = stroke(card, Theme.c.border, 1, 0)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(212,212,218)), Parent = card })
        local bar = new("Frame", { AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(0,3,0,0),
            BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, ZIndex = 4, Parent = card })
        corner(bar, 2)
        return wrap, card, st, bar
    end
    local function setScrolling(enabled) pageFrame.ScrollingEnabled = enabled end
    local function ripple(card, input)
        local sc = fitScale.Scale; local abs, size = card.AbsolutePosition, card.AbsoluteSize
        local x, y = size.X/sc/2, size.Y/sc/2
        if input and input.Position then x = (input.Position.X-abs.X)/sc; y = (input.Position.Y-abs.Y)/sc end
        local r = new("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(0,0),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 2, Parent = card })
        corner(r, 999)
        local d = (size.X/sc) * 2.2
        tween(r, { Size = UDim2.fromOffset(d,d), BackgroundTransparency = 1 }, 0.6, Enum.EasingStyle.Quart)
        Debris:AddItem(r, 0.7)
    end

    -- Tooltip + Popup
    local Tooltip = {}
    local tip = new("TextLabel", { BackgroundColor3 = Theme.c.bgMain, BackgroundTransparency = 1, TextTransparency = 1,
        Font = FONT_MAIN, TextSize = 11, TextColor3 = TEXT, Text = "", BorderSizePixel = 0, ZIndex = 200,
        Size = UDim2.fromOffset(60,22), AnchorPoint = Vector2.new(0.5,0), Visible = false, Parent = overlay })
    corner(tip, 6); local tSt = stroke(tip, Theme.c.border, 1, 1); local tipToken = 0
    function Tooltip.show(text, anchor)
        tipToken = tipToken + 1; local my = tipToken
        task.delay(0.35, function()
            if tipToken ~= my or not anchor.Parent then return end
            local sc = fitScale.Scale; local w = 60
            pcall(function() w = TextService:GetTextSize(text, 11, FONT_MAIN, Vector2.new(400,30)).X + 18 end)
            local a, o = anchor.AbsolutePosition, overlay.AbsolutePosition
            local cx = (a.X-o.X)/sc + anchor.AbsoluteSize.X/sc/2
            local y = (a.Y-o.Y)/sc + anchor.AbsoluteSize.Y/sc + 8
            cx = math.clamp(cx, w/2+6, winW-w/2-6)
            tip.Text = text; tip.Size = UDim2.fromOffset(w,22); tip.Position = UDim2.fromOffset(cx,y+4)
            tip.BackgroundColor3 = Theme.c.bgMain; tSt.Color = Theme.c.border; tip.Visible = true
            tween(tip, { Position = UDim2.fromOffset(cx,y), BackgroundTransparency = 0.05, TextTransparency = 0 }, 0.15)
            tween(tSt, { Transparency = 0.2 }, 0.15)
        end)
    end
    function Tooltip.hide()
        tipToken = tipToken + 1
        tween(tip, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.1); tween(tSt, { Transparency = 1 }, 0.1)
        local my = tipToken; task.delay(0.12, function() if tipToken == my then tip.Visible = false end end)
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
        local c = Theme.c; local sc = fitScale.Scale
        local aAbs, aSize, oAbs = anchor.AbsolutePosition, anchor.AbsoluteSize, overlay.AbsolutePosition
        local aw, ah = aSize.X/sc, aSize.Y/sc
        local ax, ay = (aAbs.X-oAbs.X)/sc, (aAbs.Y-oAbs.Y)/sc
        local options = spec.options or {}
        local ROW_H, GAP, HEAD_H, PAD = 26, 2, 22, 6
        local visible = math.min(math.max(#options,1), 6)
        local listH = visible*(ROW_H+GAP)-GAP
        local totalH = PAD + HEAD_H + 5 + listH + PAD
        local totalW = math.max(aw, 156)
        local px = math.clamp(ax + aw - totalW, 8, winW - totalW - 8)
        local openUp = (winH-(ay+ah)-12 < totalH) and (ay-12 > winH-(ay+ah)-12)
        local backdrop = new("TextButton", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1, Parent = overlay })
        backdrop.MouseButton1Click:Connect(Popup.close)
        local pf = new("Frame", { BackgroundColor3 = c.bgCard, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5, Size = UDim2.new(0, totalW, 0, 0), Parent = overlay })
        corner(pf, 10); stroke(pf, c.accent, 1.2, 0.45)
        new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205,205,212)), Parent = pf })
        if openUp then pf.AnchorPoint = Vector2.new(0,1); pf.Position = UDim2.fromOffset(px, ay-6)
        else pf.AnchorPoint = Vector2.new(0,0); pf.Position = UDim2.fromOffset(px, ay+ah+6) end
        newLabel(pf, spec.header or "Options", 10, FONT_STRONG, TEXT_DIM, { Size = UDim2.new(1,-20,0,HEAD_H), Position = UDim2.new(0,12,0,PAD), ZIndex = 6 })
        new("Frame", { Size = UDim2.new(1,-20,0,1), Position = UDim2.new(0,10,0,PAD+HEAD_H+1), BackgroundColor3 = c.border, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 6, Parent = pf })
        local list = new("ScrollingFrame", { Size = UDim2.new(1,-12,0,listH), Position = UDim2.new(0,6,0,PAD+HEAD_H+5), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = c.accent, ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6, Parent = pf })
        new("UIListLayout", { Padding = UDim.new(0,GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
        if #options == 0 then
            newLabel(list, spec.empty or "Nothing here", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1,0,0,ROW_H), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7 })
        else
            for i, name in ipairs(options) do
                local isSel = (name == spec.selected)
                local row = new("TextButton", { Size = UDim2.new(1,-4,0,ROW_H), BackgroundColor3 = isSel and c.hover or c.bgMain, BackgroundTransparency = isSel and 0 or 0.4,
                    Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 7, Parent = list })
                corner(row, 6); local rs = stroke(row, isSel and c.accent or c.border, 1, isSel and 0.2 or 0.5)
                local lbl = newLabel(row, name, 11, isSel and FONT_STRONG or FONT_MAIN, isSel and c.accent or TEXT, { Size = UDim2.new(1,-34,1,0), Position = UDim2.new(0,10,0,0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8 })
                if isSel then
                    local dot = new("Frame", { AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-10,0.5,0), Size = UDim2.fromOffset(6,6), BackgroundColor3 = c.accent, BorderSizePixel = 0, ZIndex = 8, Parent = row })
                    corner(dot, 3)
                end
                row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0, BackgroundColor3 = c.hover }, 0.1); tween(rs, { Color = c.accent, Transparency = 0.15 }, 0.1); tween(lbl, { TextColor3 = c.accent }, 0.1) end)
                row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = isSel and 0 or 0.4, BackgroundColor3 = isSel and c.hover or c.bgMain }, 0.12); tween(rs, { Color = isSel and c.accent or c.border, Transparency = isSel and 0.2 or 0.5 }, 0.12); tween(lbl, { TextColor3 = isSel and c.accent or TEXT }, 0.12) end)
                row.MouseButton1Click:Connect(function() Popup.close(); if spec.onPick then spec.onPick(name) end end)
            end
        end
        tween(pf, { Size = UDim2.new(0,totalW,0,totalH) }, 0.26, Enum.EasingStyle.Back)
        if spec.arrow then tween(spec.arrow, { Rotation = 180 }, 0.22) end
        Popup.current = { frame = pf, backdrop = backdrop, anchor = anchor, arrow = spec.arrow, w = totalW }
    end

    -- Halloween decorations
    do
        local decor = new("CanvasGroup", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, GroupTransparency = 0.12, ZIndex = 2, Parent = root })
        corner(decor, CORNER)
        local WEB, RAD = 130, 5
        local webCol = Color3.fromRGB(215,212,235)
        local function seg(parent, ax, ay, bx, by, th, col, tr)
            local dx, dy = bx-ax, by-ay
            return new("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromOffset((ax+bx)/2,(ay+by)/2),
                Size = UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),th), Rotation = math.deg(math.atan2(dy,dx)),
                BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = 2, Parent = parent })
        end
        local function buildWeb(ax, ay)
            local holder = new("Frame", { AnchorPoint = Vector2.new(ax,ay), Position = UDim2.fromScale(ax,ay),
                Size = UDim2.fromOffset(WEB,WEB), BackgroundTransparency = 1, Parent = decor })
            local function pt(x,y) return (ax == 0) and x or (WEB-x), (ay == 0) and y or (WEB-y) end
            local ang = {}
            for k = 0, RAD-1 do ang[k] = math.rad(k*90/(RAD-1)) end
            local ox, oy = pt(0,0)
            for k = 0, RAD-1 do
                local x2, y2 = pt(math.cos(ang[k])*WEB, math.sin(ang[k])*WEB)
                seg(holder, ox, oy, x2, y2, 1.4, webCol, 0.35)
            end
            for _, r in ipairs({32,62,95,128}) do
                for k = 0, RAD-2 do
                    local x1, y1 = math.cos(ang[k])*r, math.sin(ang[k])*r
                    local x2, y2 = math.cos(ang[k+1])*r, math.sin(ang[k+1])*r
                    local mx, my = (x1+x2)/2*0.88, (y1+y2)/2*0.88
                    local px1, py1 = pt(x1,y1); local pmx, pmy = pt(mx,my); local px2, py2 = pt(x2,y2)
                    seg(holder, px1, py1, pmx, pmy, 1.1, webCol, 0.45)
                    seg(holder, pmx, pmy, px2, py2, 1.1, webCol, 0.45)
                end
            end
        end
        buildWeb(0,1); buildWeb(1,1)
        local sx = -170
        local thread = new("Frame", { AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(1,sx,0,0), Size = UDim2.fromOffset(1,30),
            BackgroundColor3 = webCol, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 3, Parent = decor })
        local sp = new("TextLabel", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(1,sx,0,40), Size = UDim2.fromOffset(34,34),
            BackgroundTransparency = 1, Font = FONT_MAIN, Text = HW_SPIDER, TextSize = 22, TextColor3 = WHITE, ZIndex = 3, Parent = decor })
        task.spawn(function()
            while alive and sp.Parent do
                tween(thread, { Size = UDim2.fromOffset(1,46) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tween(sp, { Position = UDim2.new(1,sx,0,56) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(1.6)
                if not (alive and sp.Parent) then break end
                tween(thread, { Size = UDim2.fromOffset(1,30) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tween(sp, { Position = UDim2.new(1,sx,0,40) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(1.6)
            end
        end)
    end

    -- Drag / resize
    local posX, posY, tgtX, tgtY = 0,0,0,0
    local dragging, dragOrigin, startX, startY = false, nil, 0, 0
    local isMin, isAnim, resizing = false, false, false
    local function clampPos(x, y)
        local vp = viewport(); local sc = fitScale.Scale
        local hw = winW*sc/2; local hh = winH*sc/2
        return math.clamp(x, -(vp.X/2-hw+20), vp.X/2-hw+20), math.clamp(y, -(vp.Y/2-hh+20), vp.Y/2-hh+20)
    end
    grip.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if isAnim or isMin or resizing then return end
        Popup.close(); Tooltip.hide()
        local isT = input.UserInputType == Enum.UserInputType.Touch
        local startP = isT and input.Position or UserInputService:GetMouseLocation()
        local vp = viewport(); local sW, sH = winW, winH; local sS = fitScale.Scale; local sX, sY = posX, posY
        local tlX = vp.X/2 + sX - sW*sS/2; local tlY = vp.Y/2 + sY - sH*sS/2
        resizing = true
        local c1, c2, done
        local function finish() if done then return end; done = true; resizing = false; if c1 then c1:Disconnect() end; if c2 then c2:Disconnect() end end
        c1 = UserInputService.InputChanged:Connect(function(i)
            local ok = (isT and i.UserInputType == Enum.UserInputType.Touch) or (not isT and i.UserInputType == Enum.UserInputType.MouseMovement)
            if not ok then return end
            local p = isT and i.Position or UserInputService:GetMouseLocation()
            local d = p - startP
            local tW = math.clamp(sW*sS + d.X, MIN_W*sS, MAX_W*sS)
            local tH = math.clamp(sH*sS + d.Y, MIN_H*sS, MAX_H*sS)
            local cs = fitScale.Scale
            winW = math.clamp(tW/cs, MIN_W, MAX_W); winH = math.clamp(tH/cs, MIN_H, MAX_H)
            root.Size = UDim2.fromOffset(winW, winH); updateFit()
            local fs = fitScale.Scale
            posX, posY = tlX + winW*fs/2 - vp.X/2, tlY + winH*fs/2 - vp.Y/2
            tgtX, tgtY = posX, posY
            root.Position = UDim2.new(0.5, posX, 0.5, posY)
        end)
        c2 = UserInputService.InputEnded:Connect(function(i)
            local ok = (isT and i.UserInputType == Enum.UserInputType.Touch) or (not isT and i.UserInputType == Enum.UserInputType.MouseButton1)
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
    bind(RunService.RenderStepped, function(dt)
        if not resizing and (posX ~= tgtX or posY ~= tgtY) then
            local k = math.min(1, dt*22)
            posX = posX + (tgtX-posX)*k; posY = posY + (tgtY-posY)*k
            if math.abs(tgtX-posX) < 0.25 then posX = tgtX end
            if math.abs(tgtY-posY) < 0.25 then posY = tgtY end
            if not (isAnim or isMin) then root.Position = UDim2.new(0.5, posX, 0.5, posY) end
        end
    end)

    -- Minimize ball
    local ballHolder, ballPos = nil, Vector2.new(16,16)
    local function clampBall(p)
        local vp = viewport()
        return Vector2.new(math.clamp(p.X,6,vp.X-BALL-6), math.clamp(p.Y,6,vp.Y-BALL-6))
    end
    local restore
    local function createBall()
        ballPos = clampBall(ballPos)
        ballHolder = new("Frame", { Size = UDim2.fromOffset(BALL,BALL), Position = UDim2.fromOffset(ballPos.X,ballPos.Y), BackgroundTransparency = 1, ZIndex = 300, Parent = gui })
        local hScale = new("UIScale", { Scale = 0, Parent = ballHolder })
        local pulse = new("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.fromOffset(BALL,BALL), BackgroundTransparency = 1, ZIndex = 298, Parent = ballHolder })
        corner(pulse, 16); local pulseSt = stroke(pulse, Theme.c.accent, 2, 1)
        local ball = new("TextButton", { Size = UDim2.fromOffset(BALL,BALL), BackgroundColor3 = BLACK, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, ZIndex = 300, Parent = ballHolder })
        corner(ball, 16); local ballSt = stroke(ball, Theme.c.accent, 1.5, 0.4)
        new("ImageLabel", { Size = UDim2.fromOffset(40,40), Position = UDim2.new(0.5,-20,0.5,-20), BackgroundTransparency = 1, Image = LOGO_BALL_ICON, ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 305, Parent = ball })
        new("TextLabel", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-1,0,1), Size = UDim2.fromOffset(20,20),
            BackgroundTransparency = 1, Font = FONT_MAIN, Text = HW_PUMPKIN, TextSize = 14, TextColor3 = WHITE, ZIndex = 306, Parent = ball })
        tween(hScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
        task.spawn(function()
            while alive and pulse.Parent do
                pulse.Size = UDim2.fromOffset(BALL,BALL); pulseSt.Transparency = 0.5
                tween(pulse, { Size = UDim2.fromOffset(BALL+26, BALL+26) }, 1.6, Enum.EasingStyle.Quad)
                tween(pulseSt, { Transparency = 1 }, 1.6, Enum.EasingStyle.Quad)
                task.wait(2.4)
            end
        end)
        ball.MouseEnter:Connect(function() tween(ball, { BackgroundColor3 = Color3.fromRGB(34,18,46) }, 0.15); tween(ballSt, { Transparency = 0 }, 0.15); tween(hScale, { Scale = 1.07 }, 0.15, Enum.EasingStyle.Back) end)
        ball.MouseLeave:Connect(function() tween(ball, { BackgroundColor3 = BLACK }, 0.15); tween(ballSt, { Transparency = 0.4 }, 0.15); tween(hScale, { Scale = 1 }, 0.15) end)
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
                    local sX = (ballPos.X + BALL/2 < vp.X/2) and 10 or (vp.X-BALL-10)
                    ballPos = clampBall(Vector2.new(sX, ballPos.Y))
                    tween(ballHolder, { Position = UDim2.fromOffset(ballPos.X, ballPos.Y) }, 0.3, Enum.EasingStyle.Back)
                elseif not moved then restore() end
            end
        end)
    end
    local function minimize()
        if isAnim or isMin then return end
        isAnim = true; Popup.close(); Tooltip.hide()
        local cx, cy = ballPos.X + BALL/2, ballPos.Y + BALL/2
        tween(canvas, { GroupTransparency = 1 }, 0.24)
        tween(popScale, { Scale = 0.35 }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(root, { Position = UDim2.fromOffset(cx,cy) }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        setShadow(false, 0.2)
        task.wait(0.3)
        root.Visible = false; createBall()
        isMin = true; isAnim = false
    end
    restore = function()
        if isAnim or not isMin then return end
        isAnim = true
        local lx, ly = ballPos.X + BALL/2, ballPos.Y + BALL/2
        local holder = ballHolder; ballHolder = nil
        if holder then
            local sc = holder:FindFirstChildOfClass("UIScale")
            if sc then tween(sc, { Scale = 0 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
            Debris:AddItem(holder, 0.22)
        end
        task.wait(0.18)
        root.Visible = true; root.Position = UDim2.fromOffset(lx,ly)
        canvas.GroupTransparency = 1; popScale.Scale = 0.35
        tween(root, { Position = UDim2.new(0.5,posX,0.5,posY) }, 0.45, Enum.EasingStyle.Back)
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

    -- Page object
    local page = { _frame = pageFrame }

    function page.section(text, order)
        local wrap = new("Frame", { Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1, LayoutOrder = order, Parent = pageFrame })
        local dot = new("Frame", { Size = UDim2.fromOffset(4,12), Position = UDim2.new(0,2,0,3), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, Parent = wrap })
        corner(dot, 2); Theme.bind(dot, "BackgroundColor3", "accent")
        newLabel(wrap, string.upper(text), 11, FONT_STRONG, TEXT_DIM, { Size = UDim2.new(1,-16,0,18), Position = UDim2.new(0,14,0,0) })
        local line = new("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-3), BackgroundColor3 = Theme.c.accent, BorderSizePixel = 0, Parent = wrap })
        Theme.bind(line, "BackgroundColor3", "accent")
        new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1) }), Parent = line })
    end

    function page.button(label, icon, order, cb)
        local _, card, st, bar = cardBase(pageFrame, CARD_H, order, true)
        local hover = false
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-90,1,0), Position = UDim2.new(0,16,0,0) })
        local img = new("ImageLabel", { Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-40,0.5,-12), BackgroundTransparency = 1, Image = icon, ImageColor3 = TEXT, ZIndex = 3, Parent = card })
        local function render(a)
            local c = Theme.c; local d = a and 0.18 or 0
            apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
            apply(st, { Color = hover and c.accent or c.border }, d)
            apply(img, { ImageColor3 = hover and c.accent or TEXT }, d)
            apply(bar, { Size = UDim2.new(0,3,hover and 0.5 or 0,0) }, d, Enum.EasingStyle.Back)
        end
        Theme.reg(card, function(_, a) render(a) end)
        card.MouseEnter:Connect(function() hover = true render(true) end)
        card.MouseLeave:Connect(function() hover = false render(true) end)
        card.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end end)
        card.MouseButton1Click:Connect(function() if cb then cb(card) end end)
    end

    function page.toggle(key, label, order, cb)
        local state = Options[key] == true
        local _, card, st, bar = cardBase(pageFrame, CARD_H, order, true)
        local hover = false
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-90,1,0), Position = UDim2.new(0,16,0,0) })
        local track = new("Frame", { Size = UDim2.fromOffset(44,22), Position = UDim2.new(1,-58,0.5,-11), BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(track, 11); new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205,205,214)), Parent = track })
        local tSt = stroke(track, Theme.c.border, 1, 0)
        local knob = new("Frame", { Size = UDim2.fromOffset(16,16), Position = UDim2.new(0,3,0.5,-8), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = track })
        corner(knob, 8)
        local function render(a)
            local c = Theme.c; local d = a and 0.22 or 0
            apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
            apply(st, { Color = state and c.border:Lerp(c.accent,0.45) or (hover and c.border:Lerp(c.accent,0.3) or c.border) }, d)
            apply(track, { BackgroundColor3 = state and c.accent or c.trackOff }, d)
            apply(tSt, { Color = state and c.glow or c.border }, d)
            apply(knob, { Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), BackgroundColor3 = state and WHITE or Color3.fromRGB(190,178,200) }, d, Enum.EasingStyle.Back)
            apply(bar, { Size = UDim2.new(0,3,state and 0.55 or 0,0) }, d, Enum.EasingStyle.Back)
        end
        Theme.reg(card, function(_, a) render(a) end)
        Registry[key] = function(v)
            state = v == true; setOption(key, state); render(true)
            if cb then pcall(cb, state) end
        end
        card.MouseEnter:Connect(function() hover = true render(true) end)
        card.MouseLeave:Connect(function() hover = false render(true) end)
        card.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end end)
        card.MouseButton1Click:Connect(function()
            state = not state; setOption(key, state)
            tween(knob, { Size = UDim2.fromOffset(22,16) }, 0.1)
            task.delay(0.1, function() if knob.Parent then tween(knob, { Size = UDim2.fromOffset(16,16) }, 0.2, Enum.EasingStyle.Back) end end)
            render(true); if cb then cb(state) end
        end)
    end

    function page.slider(key, label, minV, maxV, order, cb)
        minV = minV or 0; maxV = maxV or 100
        local value = math.clamp(math.floor((tonumber(Options[key]) or minV) + 0.5), minV, maxV)
        local _, card, st, bar = cardBase(pageFrame, 58, order, false)
        local hover, dragging = false, false
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-110,0,20), Position = UDim2.new(0,16,0,8) })
        local numBox = new("TextBox", { Size = UDim2.fromOffset(62,24), Position = UDim2.new(1,-78,0,6), BackgroundColor3 = Theme.c.bgMain, Text = tostring(value),
            TextColor3 = Theme.c.accent, TextSize = 12, Font = FONT_STRONG, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 3, Parent = card })
        corner(numBox, 7); stroke(numBox, Theme.c.border, 1, 0)
        local hit = new("TextButton", { Size = UDim2.new(1,-32,0,24), Position = UDim2.new(0,16,1,-30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = card })
        local track = new("Frame", { Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,0.5,-3), BackgroundColor3 = Theme.c.trackOff, BorderSizePixel = 0, ZIndex = 4, Parent = hit })
        corner(track, 3)
        local r0 = (value-minV)/(maxV-minV)
        local fill = new("Frame", { Size = UDim2.new(r0,0,1,0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5, Parent = track })
        corner(fill, 3)
        local fillGrad = new("UIGradient", { Color = ColorSequence.new(Theme.c.accent, Theme.c.glow), Parent = fill })
        local knob = new("Frame", { Size = UDim2.fromOffset(14,14), Position = UDim2.new(r0,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6, Parent = track })
        corner(knob, 7); stroke(knob, Theme.c.accent, 2, 0)
        local function render(a)
            local c = Theme.c; local d = a and 0.18 or 0
            apply(card, { BackgroundColor3 = (hover or dragging) and c.hover or c.bgCard }, d)
            apply(st, { Color = (hover or dragging) and c.border:Lerp(c.accent,0.4) or c.border }, d)
            apply(bar, { Size = UDim2.new(0,3,dragging and 0.55 or 0,0) }, d, Enum.EasingStyle.Back)
            fillGrad.Color = ColorSequence.new(c.accent, c.glow)
        end
        Theme.reg(card, function(_, a) render(a) end)
        local function setValue(v, fromBox, silent)
            v = math.clamp(math.floor(v+0.5), minV, maxV)
            local changed = v ~= value; value = v
            setOption(key, value)
            local r = (value-minV)/(maxV-minV); local d = silent and 0 or 0.08
            apply(fill, { Size = UDim2.new(r,0,1,0) }, d)
            apply(knob, { Position = UDim2.new(r,0,0.5,0) }, d)
            if not fromBox then numBox.Text = tostring(value) end
            if not silent and changed and cb then cb(value) end
        end
        Registry[key] = function(v) setValue(tonumber(v) or minV, false, true) end
        local function fromX(x)
            local pos = math.clamp((x - track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1), 0, 1)
            setValue(minV + (maxV-minV)*pos, false)
        end
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; setScrolling(false); render(true); fromX(input.Position.X)
            end
        end)
        bind(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end
        end)
        bind(UserInputService.InputEnded, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false; setScrolling(true); render(true)
            end
        end)
        numBox.FocusLost:Connect(function()
            render(true)
            local n = tonumber(numBox.Text)
            if not n then numBox.Text = tostring(value); return end
            setValue(n, false)
        end)
        card.MouseEnter:Connect(function() hover = true render(true) end)
        card.MouseLeave:Connect(function() hover = false render(true) end)
    end

    function page.textbox(key, label, order, cb, placeholder)
        local initText = key and tostring(Options[key] or "") or ""
        local _, card = cardBase(pageFrame, CARD_H, order, false)
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-170,1,0), Position = UDim2.new(0,16,0,0) })
        local box = new("TextBox", { Size = UDim2.fromOffset(142,26), Position = UDim2.new(1,-156,0.5,-13), BackgroundColor3 = Theme.c.bgMain, Text = initText,
            PlaceholderText = placeholder or "Type...", PlaceholderColor3 = Color3.fromRGB(112,92,132), TextColor3 = Theme.c.accent, TextSize = 11, Font = FONT_STRONG,
            BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 3, Parent = card })
        corner(box, 7)
        new("UIPadding", { PaddingLeft = UDim.new(0,9), PaddingRight = UDim.new(0,9), Parent = box })
        stroke(box, Theme.c.border, 1, 0)
        if key then Registry[key] = function(v) local s = tostring(v or ""); setOption(key, s); box.Text = s end end
        box.FocusLost:Connect(function() if key then setOption(key, box.Text) end; if cb then cb(box.Text) end end)
        return box
    end

    function page.dropdown(label, order, spec)
        local _, card, st, bar = cardBase(pageFrame, CARD_H+4, order, true)
        local hover = false
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-170,1,0), Position = UDim2.new(0,16,0,0) })
        local box = new("Frame", { Size = UDim2.fromOffset(138,28), Position = UDim2.new(1,-152,0.5,-14), BackgroundColor3 = Theme.c.bgMain, BorderSizePixel = 0, ZIndex = 3, Parent = card })
        corner(box, 8); stroke(box, Theme.c.border, 1, 0.1)
        local display = newLabel(box, "None", 11, FONT_MAIN, TEXT_MUTED, { Size = UDim2.new(1,-30,1,0), Position = UDim2.new(0,10,0,0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 })
        local arrow = new("ImageLabel", { AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(14,14), Position = UDim2.new(1,-14,0.5,0),
            BackgroundTransparency = 1, Image = ARROW_ICON, ImageColor3 = TEXT_MUTED, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = box })
        local obj = {}
        local function render(a)
            local c = Theme.c; local d = a and 0.18 or 0
            local v = spec.get(); local isNone = (v == nil or v == "" or v == "None")
            local open = Popup.current and Popup.current.anchor == box
            display.Text = isNone and "None" or v
            apply(card, { BackgroundColor3 = hover and c.hover or c.bgCard }, d)
            apply(st, { Color = (hover or open) and c.accent or c.border }, d)
            apply(display, { TextColor3 = isNone and TEXT_MUTED or c.accent }, d)
            apply(arrow, { ImageColor3 = (hover or open) and c.accent or TEXT_MUTED }, d)
            apply(bar, { Size = UDim2.new(0,3,(hover or open) and 0.5 or 0,0) }, d, Enum.EasingStyle.Back)
        end
        obj.refresh = function() render(true) end
        Theme.reg(card, function(_, a) render(a) end)
        card.MouseEnter:Connect(function() hover = true render(true) end)
        card.MouseLeave:Connect(function() hover = false render(true) end)
        card.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ripple(card, input) end end)
        card.MouseButton1Click:Connect(function()
            Popup.open(box, { header = spec.header, options = spec.getOptions(), selected = spec.get(), empty = spec.empty, arrow = arrow,
                onPick = function(name) spec.set(name); render(true) end })
        end)
        return obj
    end

    function page.colorPicker(key, label, order)
        local EXPANDED_H = CARD_H + 168
        local wrap, card, st, bar = cardBase(pageFrame, CARD_H, order, false)
        local hover = false
        newLabel(card, label, 13, FONT_STRONG, TEXT, { Size = UDim2.new(1,-150,0,CARD_H), Position = UDim2.new(0,16,0,0) })
        local hexLbl = newLabel(card, toHex(Options[key]), 11, FONT_CODE, TEXT_MUTED, { Size = UDim2.fromOffset(70,CARD_H), Position = UDim2.new(1,-128,0,0), TextXAlignment = Enum.TextXAlignment.Right })
        local colorSq = new("TextButton", { Size = UDim2.fromOffset(30,30), Position = UDim2.new(1,-46,0,6), BackgroundColor3 = Options[key], Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6, Parent = card })
        corner(colorSq, 8); stroke(colorSq, Theme.c.border, 1.5, 0)
        local rowHit = new("TextButton", { Size = UDim2.new(1,0,0,CARD_H), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = card })
        local content = new("Frame", { Size = UDim2.new(1,0,0,EXPANDED_H-CARD_H), Position = UDim2.new(0,0,0,CARD_H), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
        new("Frame", { Size = UDim2.new(1,-28,0,1), Position = UDim2.new(0,14,0,0), BackgroundColor3 = Theme.c.border, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = content })
        local preview = new("Frame", { Size = UDim2.fromOffset(64,64), Position = UDim2.new(0,16,0,14), BackgroundColor3 = Options[key], BorderSizePixel = 0, ZIndex = 3, Parent = content })
        corner(preview, 10); stroke(preview, Theme.c.border, 1.5, 0)
        local previewHex = newLabel(content, toHex(Options[key]), 12, FONT_CODE, TEXT, { Size = UDim2.fromOffset(100,18), Position = UDim2.new(0,16,0,84) })
        local SV = 118
        local sv = new("Frame", { Size = UDim2.fromOffset(SV,SV), Position = UDim2.new(1,-(SV+16),0,14), BackgroundColor3 = Color3.fromRGB(255,0,0), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = content })
        corner(sv, 8); stroke(sv, Theme.c.border, 1, 0.2)
        local wl = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = sv })
        corner(wl, 8); new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }), Parent = wl })
        local bl = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 5, Parent = sv })
        corner(bl, 8); new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }), Parent = bl })
        local svHit = new("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 7, Parent = sv })
        local svCur = new("Frame", { Size = UDim2.fromOffset(16,16), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8, Parent = sv })
        corner(svCur, 8); stroke(svCur, WHITE, 2, 0)
        local hueWrap = new("Frame", { Size = UDim2.new(1,-32,0,18), Position = UDim2.new(0,16,0,14+SV+12), BackgroundTransparency = 1, ZIndex = 3, Parent = content })
        local hueTrack = new("Frame", { Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,0.5,-6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3, Parent = hueWrap })
        corner(hueTrack, 6)
        new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)) }), Parent = hueTrack })
        local hueHit = new("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = hueWrap })
        local hueCur = new("Frame", { Size = UDim2.fromOffset(16,20), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = Color3.fromRGB(255,0,0), BorderSizePixel = 0, ZIndex = 6, Parent = hueWrap })
        corner(hueCur, 6); stroke(hueCur, WHITE, 2.5, 0)
        local h0, s0, v0 = rgbToHsv(Options[key])
        local picker = { hue = h0, sat = s0, val = v0, svDrag = false, hueDrag = false, open = false }
        local function placeSV() svCur.Position = UDim2.new(picker.sat,0,1-picker.val,0) end
        local function placeHue() hueCur.Position = UDim2.new(picker.hue/360,0,0.5,0); hueCur.BackgroundColor3 = hsvToRgb(picker.hue,1,1) end
        local function commit()
            local c = hsvToRgb(picker.hue, picker.sat, picker.val)
            genv.BabisESPColor = c; setOption(key, c)
            preview.BackgroundColor3 = c; colorSq.BackgroundColor3 = c
            local hx = toHex(c); hexLbl.Text = hx; previewHex.Text = hx
        end
        placeSV(); placeHue(); sv.BackgroundColor3 = hsvToRgb(picker.hue,1,1)
        Registry[key] = function(c)
            if typeof(c) ~= "Color3" then return end
            local h, s, v = rgbToHsv(c)
            picker.hue, picker.sat, picker.val = h, s, v
            placeSV(); placeHue(); sv.BackgroundColor3 = hsvToRgb(h,1,1); commit()
        end
        local function updateSV(mx, my)
            local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
            if as.X <= 0 or as.Y <= 0 then return end
            picker.sat = math.clamp((mx-ap.X)/as.X, 0, 1); picker.val = 1 - math.clamp((my-ap.Y)/as.Y, 0, 1)
            placeSV(); commit()
        end
        local function updateHue(mx)
            local ap, as = hueWrap.AbsolutePosition, hueWrap.AbsoluteSize
            if as.X <= 0 then return end
            picker.hue = math.clamp((mx-ap.X)/as.X, 0, 1) * 359.99
            placeHue(); sv.BackgroundColor3 = hsvToRgb(picker.hue,1,1); commit()
        end
        svHit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then picker.svDrag = true; setScrolling(false); updateSV(input.Position.X, input.Position.Y) end end)
        hueHit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then picker.hueDrag = true; setScrolling(false); updateHue(input.Position.X) end end)
        bind(UserInputService.InputChanged, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if picker.svDrag then updateSV(input.Position.X, input.Position.Y)
            elseif picker.hueDrag then updateHue(input.Position.X) end
        end)
        bind(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if picker.svDrag or picker.hueDrag then setScrolling(true) end
                picker.svDrag, picker.hueDrag = false, false
            end
        end)
        local function render(a)
            local c = Theme.c; local d = a and 0.2 or 0
            apply(card, { BackgroundColor3 = (hover or picker.open) and c.hover or c.bgCard }, d)
            apply(st, { Color = picker.open and c.accent or (hover and c.border:Lerp(c.accent,0.3) or c.border) }, d)
        end
        Theme.reg(card, function(_, a) render(a) end)
        local function setOpen(open)
            picker.open = open
            tween(wrap, { Size = UDim2.new(1,0,0,open and EXPANDED_H or CARD_H) }, 0.34, Enum.EasingStyle.Quint)
            render(true)
        end
        colorSq.Activated:Connect(function() setOpen(not picker.open) end)
        rowHit.Activated:Connect(function() setOpen(not picker.open) end)
        rowHit.MouseEnter:Connect(function() hover = true render(true) end)
        rowHit.MouseLeave:Connect(function() hover = false render(true) end)
    end

    function page.buttonRow(order, defs)
        local wrap = new("Frame", { Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, LayoutOrder = order, Parent = pageFrame })
        wrap:SetAttribute("Entrance", true)
        local row = new("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Parent = wrap })
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
        local n = #defs; local buttons = {}
        for i, def in ipairs(defs) do
            local btn = new("TextButton", { Size = UDim2.new(1/n, -(8*(n-1)/n), 1, 0), BackgroundColor3 = Theme.c.bgCard, Text = def.text, TextColor3 = TEXT,
                Font = FONT_MAIN, TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, LayoutOrder = i, Parent = row })
            corner(btn, 9); local bs = stroke(btn, Theme.c.border, 1, 0.2)
            new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(212,212,218)), Parent = btn })
            local hover = false
            local function render(a)
                local c = Theme.c; local d = a and 0.15 or 0
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

    -- Unload + close
    local function destroyAll()
        if not alive then return end
        alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
        Confirm.destroy()
        task.delay(6, Notifier.destroy)
        genv.BabisUnload = nil
    end
    genv.BabisUnload = destroyAll

    local function closeWindow()
        if not alive then return end
        Popup.close()
        if isMin then destroyAll(); return end
        tween(canvas, { GroupTransparency = 1 }, 0.25)
        tween(popScale, { Scale = 0.88 }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        setShadow(false, 0.2)
        task.delay(0.3, destroyAll)
    end
    closeBtnHeader.MouseButton1Click:Connect(function()
        Confirm.ask("ARE YOU SURE?", "", closeWindow)
    end)

    local function boot()
        if typeof(Options.theme_color) == "Color3" and not colorMatch(Options.theme_color, ORIGINAL_THEME.accent, 0.004) then
            Theme.set(Options.theme_color)
        end
        pageFrame.Visible = true
        pageFrame.CanvasPosition = Vector2.new(0,0)
        local wraps = {}
        for _, ch in ipairs(pageFrame:GetChildren()) do
            if ch:IsA("Frame") and ch:GetAttribute("Entrance") then wraps[#wraps+1] = ch end
        end
        table.sort(wraps, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        contentGroup.GroupTransparency = 0.65
        tween(contentGroup, { GroupTransparency = 0 }, 0.28, Enum.EasingStyle.Quad)
        for i, w in ipairs(wraps) do
            local card = w:FindFirstChild("Card")
            if card then
                card.Position = UDim2.new(0,18,0,0)
                task.delay((i-1)*0.03, function()
                    if card.Parent then tween(card, { Position = UDim2.new(0,0,0,0) }, 0.4, Enum.EasingStyle.Quint) end
                end)
            end
        end
        root.Rotation = -4
        task.delay(0.12, function()
            if not alive then return end
            tween(canvas, { GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Quad)
            tween(popScale, { Scale = 1 }, 0.6, Enum.EasingStyle.Back)
            tween(root, { Rotation = 0 }, 0.6, Enum.EasingStyle.Back)
            setShadow(true, 0.6)
        end)
    end

    return { settings = page, boot = boot, close = closeWindow, minimize = minimize }
end

return {
    newWindow = newWindow,
    notify = notify,
    confirm = Confirm.ask,
    setTheme = Theme.set,
    unload = function() if genv.BabisUnload then genv.BabisUnload() end end,
    registry = Registry,
    options = Options,
    setOption = setOption,
    config = ConfigSys,
    serialize = serializeOptions,
    deserialize = deserializeOptions,
    persistKeys = PERSIST_KEYS,
    ORIGINAL_THEME = ORIGINAL_THEME,
    setPersistKeys = function(keys) PERSIST_KEYS = keys end,
    __theme = Theme,
}

end)()
-- ╚══════════════════ END LIBRARY ══════════════════╝
