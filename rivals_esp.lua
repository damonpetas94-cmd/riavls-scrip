-- Rivals ESP Script with Rayfield UI + Key System
-- Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =============================================
-- KEY SYSTEM CONFIG
-- =============================================
local KEY_SYSTEM_ENABLED = true
local VALID_KEYS = {
    -- Add your keys here, or replace verifyKey() with a real HTTP check
    ["RIVALS-XXXX-XXXX-XXXX"] = true,
    ["RIVALS-FREE-2024-KEY1"] = true,
}
local KEY_WEBSITE = "https://luarmor.org/" -- Replace with your key site

-- =============================================
-- KEY VERIFICATION FUNCTION
-- (Replace with HTTP-based check if needed)
-- =============================================
local function verifyKey(key)
    -- Option A: Local key list (simple)
    if VALID_KEYS[key] then
        return true, "valid"
    end

    -- Option B: HTTP verification (uncomment to use)
    --[[
    local success, response = pcall(function()
        return game:HttpGet("https://yoursite.com/verify?key=" .. key)
    end)
    if success and response == "valid" then
        return true, "valid"
    elseif success and response == "expired" then
        return false, "expired"
    end
    ]]

    return false, "invalid"
end

-- =============================================
-- ESP VARIABLES
-- =============================================
local ESPSettings = {
    Enabled = false,
    BoxESP = false,
    NameESP = false,
    HealthBar = false,
    TracerLines = false,
    DistanceESP = false,
    TeamCheck = true,
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    TracerColor = Color3.fromRGB(255, 0, 0),
    MaxDistance = 500,
}

local ESPObjects = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =============================================
-- ESP DRAWING FUNCTIONS
-- =============================================
local function createESPForPlayer(player)
    if player == LocalPlayer then return end

    local drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
    }

    -- Box
    drawings.Box.Visible = false
    drawings.Box.Color = ESPSettings.BoxColor
    drawings.Box.Thickness = 1.5
    drawings.Box.Filled = false

    -- Name
    drawings.Name.Visible = false
    drawings.Name.Color = ESPSettings.NameColor
    drawings.Name.Size = 13
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Font = Drawing.Fonts.UI

    -- Health Bar Background
    drawings.HealthBarBG.Visible = false
    drawings.HealthBarBG.Color = Color3.fromRGB(0, 0, 0)
    drawings.HealthBarBG.Thickness = 1
    drawings.HealthBarBG.Filled = true

    -- Health Bar
    drawings.HealthBar.Visible = false
    drawings.HealthBar.Color = ESPSettings.HealthColor
    drawings.HealthBar.Thickness = 1
    drawings.HealthBar.Filled = true

    -- Tracer
    drawings.Tracer.Visible = false
    drawings.Tracer.Color = ESPSettings.TracerColor
    drawings.Tracer.Thickness = 1

    -- Distance
    drawings.Distance.Visible = false
    drawings.Distance.Color = Color3.fromRGB(255, 255, 255)
    drawings.Distance.Size = 11
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Font = Drawing.Fonts.UI

    ESPObjects[player] = drawings
end

local function removeESPForPlayer(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    for player, drawings in pairs(ESPObjects) do
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local head = character and character:FindFirstChild("Head")

        -- Hide all if dead/no character
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        -- Team check
        if ESPSettings.TeamCheck and player.Team == LocalPlayer.Team then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        -- Distance check
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = localRoot and (rootPart.Position - localRoot.Position).Magnitude or 0
        if distance > ESPSettings.MaxDistance then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        -- World to screen
        local topPos, topVisible = Camera:WorldToViewportPoint((head or rootPart).Position + Vector3.new(0, 0.7, 0))
        local botPos, botVisible = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 2.5, 0))

        if not topVisible then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        local boxHeight = math.abs(topPos.Y - botPos.Y)
        local boxWidth = boxHeight * 0.65
        local boxX = topPos.X - boxWidth / 2
        local boxY = topPos.Y

        -- Box ESP
        if ESPSettings.Enabled and ESPSettings.BoxESP then
            drawings.Box.Visible = true
            drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
            drawings.Box.Position = Vector2.new(boxX, boxY)
            drawings.Box.Color = ESPSettings.BoxColor
        else
            drawings.Box.Visible = false
        end

        -- Name ESP
        if ESPSettings.Enabled and ESPSettings.NameESP then
            drawings.Name.Visible = true
            drawings.Name.Text = player.DisplayName
            drawings.Name.Position = Vector2.new(topPos.X, topPos.Y - 16)
            drawings.Name.Color = ESPSettings.NameColor
        else
            drawings.Name.Visible = false
        end

        -- Health Bar
        if ESPSettings.Enabled and ESPSettings.HealthBar then
            local hpPercent = humanoid.Health / humanoid.MaxHealth
            local barX = boxX - 6
            local barHeight = boxHeight

            drawings.HealthBarBG.Visible = true
            drawings.HealthBarBG.Size = Vector2.new(4, barHeight + 2)
            drawings.HealthBarBG.Position = Vector2.new(barX - 1, boxY - 1)

            drawings.HealthBar.Visible = true
            drawings.HealthBar.Size = Vector2.new(4, barHeight * hpPercent)
            drawings.HealthBar.Position = Vector2.new(barX, boxY + barHeight - (barHeight * hpPercent))
            drawings.HealthBar.Color = Color3.fromRGB(
                math.floor(255 * (1 - hpPercent)),
                math.floor(255 * hpPercent),
                0
            )
        else
            drawings.HealthBarBG.Visible = false
            drawings.HealthBar.Visible = false
        end

        -- Tracer Lines
        if ESPSettings.Enabled and ESPSettings.TracerLines then
            drawings.Tracer.Visible = true
            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            drawings.Tracer.To = Vector2.new(topPos.X, botPos.Y)
            drawings.Tracer.Color = ESPSettings.TracerColor
        else
            drawings.Tracer.Visible = false
        end

        -- Distance ESP
        if ESPSettings.Enabled and ESPSettings.DistanceESP then
            drawings.Distance.Visible = true
            drawings.Distance.Text = math.floor(distance) .. "m"
            drawings.Distance.Position = Vector2.new(topPos.X, botPos.Y + 4)
        else
            drawings.Distance.Visible = false
        end
    end
end

-- Setup players
local function setupESP()
    for _, player in pairs(Players:GetPlayers()) do
        createESPForPlayer(player)
    end
    Players.PlayerAdded:Connect(createESPForPlayer)
    Players.PlayerRemoving:Connect(removeESPForPlayer)

    RunService.RenderStepped:Connect(function()
        if ESPSettings.Enabled then
            updateESP()
        end
    end)
end

-- =============================================
-- KEY SYSTEM UI (Rayfield)
-- =============================================
local function showKeySystem()
    local KeyWindow = Rayfield:CreateWindow({
        Name = "🔑 Rivals ESP — Key System",
        LoadingTitle = "Checking Key...",
        LoadingSubtitle = "by RivalsESP",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false, -- We handle it manually
    })

    local KeyTab = KeyWindow:CreateTab("Key Verification", "key")

    KeyTab:CreateSection("Enter Your Key")

    local keyInput = ""

    KeyTab:CreateInput({
        Name = "Key",
        PlaceholderText = "Enter your key here...",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            keyInput = value
        end,
    })

    KeyTab:CreateButton({
        Name = "✅ Submit Key",
        Callback = function()
            if keyInput == "" then
                Rayfield:Notify({
                    Title = "Key System",
                    Content = "Please enter a key first!",
                    Duration = 3,
                    Image = "rbxassetid://4483345998",
                })
                return
            end

            local isValid, status = verifyKey(keyInput)

            if isValid then
                Rayfield:Notify({
                    Title = "✅ Key Accepted",
                    Content = "Welcome! Loading ESP...",
                    Duration = 3,
                    Image = "rbxassetid://4483345998",
                })

                task.delay(1.5, function()
                    KeyWindow:Destroy()
                    loadMainUI()
                end)
            else
                local msg = "Invalid key! Try again."
                if status == "expired" then msg = "Your key has expired!" end
                Rayfield:Notify({
                    Title = "❌ Invalid Key",
                    Content = msg,
                    Duration = 4,
                    Image = "rbxassetid://4483345998",
                })
            end
        end,
    })

    KeyTab:CreateButton({
        Name = "🌐 Get a Key",
        Callback = function()
            setclipboard(KEY_WEBSITE)
            Rayfield:Notify({
                Title = "Key Website",
                Content = "URL copied to clipboard! Paste in your browser.",
                Duration = 4,
                Image = "rbxassetid://4483345998",
            })
        end,
    })
end

-- =============================================
-- MAIN ESP UI (Rayfield)
-- =============================================
function loadMainUI()
    setupESP()

    local Window = Rayfield:CreateWindow({
        Name = "Rivals ESP",
        LoadingTitle = "Rivals ESP",
        LoadingSubtitle = "ESP Loaded ✓",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "RivalsESP",
            FileName = "Config",
        },
        KeySystem = false,
    })

    -- ── ESP Tab ──
    local ESPTab = Window:CreateTab("ESP", "eye")

    ESPTab:CreateSection("Master Toggle")

    ESPTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "ESP_Master",
        Callback = function(val)
            ESPSettings.Enabled = val
            if not val then
                for _, drawings in pairs(ESPObjects) do
                    for _, d in pairs(drawings) do d.Visible = false end
                end
            end
        end,
    })

    ESPTab:CreateSection("ESP Options")

    ESPTab:CreateToggle({
        Name = "Box ESP",
        CurrentValue = false,
        Flag = "ESP_Box",
        Callback = function(val) ESPSettings.BoxESP = val end,
    })

    ESPTab:CreateToggle({
        Name = "Name ESP",
        CurrentValue = false,
        Flag = "ESP_Name",
        Callback = function(val) ESPSettings.NameESP = val end,
    })

    ESPTab:CreateToggle({
        Name = "Health Bar",
        CurrentValue = false,
        Flag = "ESP_Health",
        Callback = function(val) ESPSettings.HealthBar = val end,
    })

    ESPTab:CreateToggle({
        Name = "Tracer Lines",
        CurrentValue = false,
        Flag = "ESP_Tracer",
        Callback = function(val) ESPSettings.TracerLines = val end,
    })

    ESPTab:CreateToggle({
        Name = "Distance ESP",
        CurrentValue = false,
        Flag = "ESP_Distance",
        Callback = function(val) ESPSettings.DistanceESP = val end,
    })

    ESPTab:CreateToggle({
        Name = "Team Check (hide teammates)",
        CurrentValue = true,
        Flag = "ESP_TeamCheck",
        Callback = function(val) ESPSettings.TeamCheck = val end,
    })

    -- ── Settings Tab ──
    local SettingsTab = Window:CreateTab("Settings", "settings")

    SettingsTab:CreateSection("ESP Appearance")

    SettingsTab:CreateSlider({
        Name = "Max Distance",
        Range = {50, 2000},
        Increment = 50,
        Suffix = "studs",
        CurrentValue = 500,
        Flag = "ESP_MaxDist",
        Callback = function(val) ESPSettings.MaxDistance = val end,
    })

    SettingsTab:CreateColorPicker({
        Name = "Box Color",
        Color = Color3.fromRGB(255, 0, 0),
        Flag = "ESP_BoxColor",
        Callback = function(val) ESPSettings.BoxColor = val end,
    })

    SettingsTab:CreateColorPicker({
        Name = "Name Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "ESP_NameColor",
        Callback = function(val) ESPSettings.NameColor = val end,
    })

    SettingsTab:CreateColorPicker({
        Name = "Tracer Color",
        Color = Color3.fromRGB(255, 0, 0),
        Flag = "ESP_TracerColor",
        Callback = function(val) ESPSettings.TracerColor = val end,
    })

    -- ── Info Tab ──
    local InfoTab = Window:CreateTab("Info", "info")

    InfoTab:CreateSection("About")
    InfoTab:CreateParagraph({
        Title = "Rivals ESP",
        Content = "ESP-only script with Rayfield UI.\nBox • Name • Health • Tracers • Distance\n\nPress RightShift to toggle the UI.",
    })

    InfoTab:CreateSection("Keybinds")
    InfoTab:CreateKeybind({
        Name = "Toggle UI",
        CurrentKeybind = "RightShift",
        HoldToInteract = false,
        Flag = "UI_Toggle",
        Callback = function()
            -- Rayfield handles this automatically
        end,
    })
end

-- =============================================
-- ENTRY POINT
-- =============================================
if KEY_SYSTEM_ENABLED then
    showKeySystem()
else
    setupESP()
    loadMainUI()
end
