--[[
    ROCKET | Blade Ball Auto Parry + Skin Changer (Modern UI)
    Rocket Way | v2.0
    Управление: RightShift — открыть/закрыть меню
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============ КОНФИГ ============
local Config = {
    AutoParry = true,
    ParryRange = 20,
    ParryDelay = 0.05,
    AutoClick = true,
    ShowNotifications = true,
    CurrentSkinName = "Default",
    ApplyTexture = true,
    ApplyMesh = false,
    ApplyScale = false,
    ApplyOffset = false,
}

-- ============ СКИНЫ ============
local SkinLibrary = {
    ["Default"]   = { texture = "", mesh = "", scale = Vector3.new(1,1,1), offset = Vector3.new(0,0,0) },
    ["Neon Blue"] = { texture = "rbxassetid://6031094667", mesh = "", scale = Vector3.new(1.2,1.2,1.2), offset = Vector3.new(0,0,0) },
    ["Crimson"]   = { texture = "rbxassetid://6031091004", mesh = "", scale = Vector3.new(1.1,1.1,1.1), offset = Vector3.new(0,0.1,0) },
    ["Rainbow"]   = { texture = "rbxassetid://6031075931", mesh = "", scale = Vector3.new(1,1,1), offset = Vector3.new(0,0,0) },
    ["Frost"]     = { texture = "rbxassetid://6034287458", mesh = "", scale = Vector3.new(0.9,0.9,0.9), offset = Vector3.new(0,-0.05,0) },
    ["Gold"]      = { texture = "rbxassetid://6031075931", mesh = "", scale = Vector3.new(1.15,1.15,1.15), offset = Vector3.new(0,0,0) },
    ["Shadow"]    = { texture = "rbxassetid://6031091004", mesh = "", scale = Vector3.new(1,1,1), offset = Vector3.new(0,0,0) },
}

-- ============ ПАЛИТРА ============
local Theme = {
    Bg          = Color3.fromRGB(18, 18, 24),
    BgLight     = Color3.fromRGB(28, 28, 38),
    Accent      = Color3.fromRGB(88, 130, 255),
    AccentDark  = Color3.fromRGB(60, 95, 200),
    Text        = Color3.fromRGB(235, 235, 245),
    TextDim     = Color3.fromRGB(150, 150, 165),
    Success     = Color3.fromRGB(70, 200, 130),
    Danger      = Color3.fromRGB(230, 80, 90),
    Stroke      = Color3.fromRGB(45, 45, 60),
}

-- ============ УТИЛИТЫ ============
local function Create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function Stroke(parent, color, thick)
    return Create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function Gradient(parent, c1, c2, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 90,
    }, parent)
end

local function Notify(text)
    if not Config.ShowNotifications then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ROCKET", Text = text, Duration = 3,
        })
    end)
end

-- ============ МЕЧ И СКИНЫ ============
local function GetSword()
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
        end
    end
    return nil
end

local function FindMesh(tool)
    if not tool then return nil end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return nil end
    local m = handle:FindFirstChildOfClass("SpecialMesh")
    if m then return m end
    for _, o in ipairs(handle:GetDescendants()) do
        if o:IsA("SpecialMesh") then return o end
    end
    return nil
end

local function ApplySkin(name)
    local skin = SkinLibrary[name]
    if not skin then Notify("Скин не найден: "..name) return end
    local tool = GetSword()
    if not tool then Notify("Меч не в руках") return end

    local mesh = FindMesh(tool)

    if Config.ApplyTexture and skin.texture ~= "" then
        pcall(function() tool.TextureId = skin.texture end)
    end
    if mesh then
        if Config.ApplyMesh and skin.mesh ~= "" then
            pcall(function() mesh.MeshId = skin.mesh end)
        end
        if skin.texture ~= "" then
            pcall(function() mesh.TextureId = skin.texture end)
        end
        if Config.ApplyScale and skin.scale then
            pcall(function() mesh.Scale = skin.scale end)
        end
        if Config.ApplyOffset and skin.offset then
            pcall(function() mesh.Offset = skin.offset end)
        end
    end
    Config.CurrentSkinName = name
    Notify("Скин: "..name)
end

local function HookSwordChanges()
    local char = LocalPlayer.Character
    if char then
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then task.wait(0.1) ApplySkin(Config.CurrentSkinName) end
        end)
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        bp.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then task.wait(0.1) ApplySkin(Config.CurrentSkinName) end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) HookSwordChanges() ApplySkin(Config.CurrentSkinName)
end)
HookSwordChanges()

-- ============ AUTO PARRY ============
local function GetBall()
    for _, o in ipairs(workspace:GetDescendants()) do
        if (o.Name == "Ball" or o.Name:lower():find("ball")) and o:IsA("BasePart") then
            return o
        end
    end
    return nil
end

local function IsTargetingMe(ball)
    if not ball then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local dist = (ball.Position - hrp.Position).Magnitude
    if dist > Config.ParryRange then return false end
    local vel = ball.AssemblyLinearVelocity
    if vel.Magnitude < 1 then return false end
    return vel.Unit:Dot((hrp.Position - ball.Position).Unit) > 0.5
end

local lastParry = 0
local function Parry()
    local n = tick()
    if n - lastParry < Config.ParryDelay then return end
    lastParry = n
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0,0))
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(0,0))
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0,0,0,true,game,1)
        task.wait(0.01)
        vim:SendMouseButtonEvent(0,0,0,false,game,1)
    end)
end

RunService.Heartbeat:Connect(function()
    if not Config.AutoParry then return end
    local b = GetBall()
    if b and IsTargetingMe(b) then Parry() end
end)

-- ============================================================
-- ==================== MODERN UI =============================
-- ============================================================

local ScreenGui = Create("ScreenGui", {
    Name = "RocketUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ---- Главное окно ----
local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 480, 0, 340),
    Position = UDim2.new(0.5, -240, 0.5, -170),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    Visible = true,
}, ScreenGui)
Corner(Main, 12)
Stroke(Main, Theme.Stroke, 1)

-- Акцентная полоса сверху
local TopBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
}, Main)
Corner(TopBar, 3)
Gradient(TopBar, Theme.Accent, Color3.fromRGB(160, 100, 255), 0)

-- ---- Перетаскивание ----
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ---- Логотип и заголовок ----
local Logo = Create("Frame", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 14, 0, 14),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
}, Main)
Corner(Logo, 8)
Gradient(Logo, Theme.Accent, Color3.fromRGB(160, 100, 255), 45)
Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "R",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
}, Logo)

Create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 18),
    Position = UDim2.new(0, 54, 0, 12),
    BackgroundTransparency = 1,
    Text = "ROCKET",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)
Create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 14),
    Position = UDim2.new(0, 54, 0, 28),
    BackgroundTransparency = 1,
    Text = "Blade Ball • v2.0",
    TextColor3 = Theme.TextDim,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)

-- ---- Кнопка закрытия ----
local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -36, 0, 16),
    BackgroundColor3 = Theme.BgLight,
    Text = "×",
    TextColor3 = Theme.TextDim,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, Main)
Corner(CloseBtn, 6)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Danger, TextColor3 = Color3.fromRGB(255,255,255) }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.BgLight, TextColor3 = Theme.TextDim }):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingBtn.Visible = true
end)

-- ---- Разделитель ----
Create("Frame", {
    Size = UDim2.new(1, -28, 0, 1),
    Position = UDim2.new(0, 14, 0, 52),
    BackgroundColor3 = Theme.Stroke,
    BorderSizePixel = 0,
}, Main)

-- ---- Вкладки ----
local TabBar = Create("Frame", {
    Size = UDim2.new(1, -28, 0, 34),
    Position = UDim2.new(0, 14, 0, 62),
    BackgroundColor3 = Theme.BgLight,
    BorderSizePixel = 0,
}, Main)
Corner(TabBar, 8)

local TabContainer = Create("Frame", {
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
}, TabBar)

local Tabs = {}
local TabButtons = {}
local currentTab = nil

local function SelectTab(name)
    for n, frame in pairs(Tabs) do frame.Visible = (n == name) end
    for n, btn in pairs(TabButtons) do
        local active = (n == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and Theme.Accent or Theme.BgLight,
            TextColor3 = active and Color3.fromRGB(255,255,255) or Theme.TextDim,
        }):Play()
    end
    currentTab = name
end

local function MakeTab(name, index)
    local btn = Create("TextButton", {
        Size = UDim2.new(1/3, -2, 1, 0),
        Position = UDim2.new((index - 1) / 3, 0, 0, 0),
        BackgroundColor3 = Theme.BgLight,
        Text = name,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, TabContainer)
    Corner(btn, 6)
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
    TabButtons[name] = btn
end

-- Контейнер контента
local Content = Create("Frame", {
    Size = UDim2.new(1, -28, 1, -140),
    Position = UDim2.new(0, 14, 0, 106),
    BackgroundTransparency = 1,
}, Main)

-- Создаём вкладки
for i, name in ipairs({ "Main", "Skins", "Settings" }) do
    MakeTab(name, i)
    Tabs[name] = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, Content)
end

-- ============ ХЕЛПЕРЫ UI ============
local function MakeToggleRow(parent, text, key, y)
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, y),
        BackgroundColor3 = Theme.BgLight,
        BorderSizePixel = 0,
    }, parent)
    Corner(row, 8)

    Create("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local track = Create("Frame", {
        Size = UDim2.new(0, 42, 0, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = Config[key] and Theme.Success or Color3.fromRGB(60,60,75),
        BorderSizePixel = 0,
    }, row)
    Corner(track, 11)

    local knob = Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = Config[key] and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0,
    }, track)
    Corner(knob, 8)

    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, row)

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        local state = Config[key]
        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.Success or Color3.fromRGB(60,60,75)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        }):Play()
    end)
end

local function MakeSliderRow(parent, text, key, min, max, y, callback)
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, y),
        BackgroundColor3 = Theme.BgLight,
        BorderSizePixel = 0,
    }, parent)
    Corner(row, 8)

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(Config[key]),
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local barBg = Create("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 34),
        BackgroundColor3 = Color3.fromRGB(45,45,60),
        BorderSizePixel = 0,
    }, row)
    Corner(barBg, 3)

    local fill = Create("Frame", {
        Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, barBg)
    Corner(fill, 3)

    local dragging2 = false
    local track = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, barBg)

    local function update(input)
        local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        Config[key] = val
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = text .. ": " .. string.format("%.2f", val)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = false
        end
    end)
end

-- ============ ВКЛАДКА MAIN ============
MakeToggleRow(Tabs.Main, "Auto Parry", "AutoParry", 0)
MakeToggleRow(Tabs.Main, "Auto Click", "AutoClick", 48)
MakeSliderRow(Tabs.Main, "Parry Range", "ParryRange", 5, 60, 96)
MakeSliderRow(Tabs.Main, "Parry Delay", "ParryDelay", 0.01, 0.5, 154)

-- ============ ВКЛАДКА SKINS ============
local scroll = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Tabs.Skins)

local skinKeys = {}
for k, _ in pairs(SkinLibrary) do table.insert(skinKeys, k) end
table.sort(skinKeys)

local skinButtons = {}
local y = 0
for _, name in ipairs(skinKeys) do
    local btn = Create("TextButton", {
        Size = UDim2.new(1, -6, 0, 38),
        Position = UDim2.new(0, 0, 0, y),
        BackgroundColor3 = (name == Config.CurrentSkinName) and Theme.Accent or Theme.BgLight,
        Text = "  " .. name,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, scroll)
    Corner(btn, 8)
    Stroke(btn, Theme.Stroke, 1)

    btn.MouseEnter:Connect(function()
        if Config.CurrentSkinName ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(40,40,55) }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if Config.CurrentSkinName ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.BgLight }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        ApplySkin(name)
        for n, b in pairs(skinButtons) do
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = (n == name) and Theme.Accent or Theme.BgLight
            }):Play()
        end
    end)
    skinButtons[name] = btn
    y = y + 44
end

-- ============ ВКЛАДКА SETTINGS ============
MakeToggleRow(Tabs.Settings, "Apply Texture", "ApplyTexture", 0)
MakeToggleRow(Tabs.Settings, "Apply Mesh", "ApplyMesh", 48)
MakeToggleRow(Tabs.Settings, "Apply Scale", "ApplyScale", 96)
MakeToggleRow(Tabs.Settings, "Apply Offset", "ApplyOffset", 144)
MakeToggleRow(Tabs.Settings, "Notifications", "ShowNotifications", 192)

-- ============ ПЛАВАЮЩАЯ КНОПКА ============
local FloatingBtn = Create("TextButton", {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0, 20, 0.5, -25),
    BackgroundColor3 = Theme.Accent,
    Text = "R",
    TextColor3 = Color3.fromRGB(255,255,255),
    Font = Enum.Font.GothamBol
