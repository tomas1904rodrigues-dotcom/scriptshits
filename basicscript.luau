repeat task.wait() until game:IsLoaded()

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local noclipEnabled    = false
local noclipConnection = nil
local currentSpeed     = 16
local savedCFrame      = nil
local autoMoneyEnabled = false
local moneyCount       = 0
local moneyInterval    = 1.0

-- ================================================
-- PLACEHOLDERS (ajusta com Remote Spy)
-- MONEY_FOLDER: nome da pasta no workspace com as moedas
-- MONEY_REMOTE: caminho do RemoteEvent de recolha
-- ================================================
local MONEY_FOLDER = "DroppedMoney"
local MONEY_REMOTE = {"ReplicatedStorage", "Remotes", "CollectMoney"}

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "Mine for Anime Fruits - Simple Tools",
    LoadingTitle    = "A carregar...",
    LoadingSubtitle = "Simple Tools v1.2",
    ConfigurationSaving = { Enabled = false },
    Discord         = { Enabled = false },
    KeySystem       = false,
})

local Tab = Window:CreateTab("Main", nil)

-- ================================================
-- NOCLIP
-- ================================================

Tab:CreateSection("Noclip")

local function setNoclip(state)
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if noclipEnabled then
        task.wait(0.5)
        setNoclip(true)
    end
end)

Tab:CreateToggle({
    Name         = "Noclip",
    CurrentValue = false,
    Flag         = "NoclipToggle",
    Callback     = function(state)
        noclipEnabled = state
        setNoclip(state)
        Rayfield:Notify({
            Title    = "Noclip",
            Content  = state and "Activado!" or "Desactivado.",
            Duration = 2.5,
        })
    end,
})

-- ================================================
-- WALKSPEED
-- ================================================

Tab:CreateSection("WalkSpeed")

local function applySpeed(speed)
    local character = LocalPlayer.Character
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        task.wait(0.5)
        humanoid.WalkSpeed = currentSpeed
    end
end)

Tab:CreateSlider({
    Name         = "WalkSpeed",
    Range        = {16, 150},
    Increment    = 1,
    Suffix       = " studs/s",
    CurrentValue = 16,
    Flag         = "WalkSpeedSlider",
    Callback     = function(value)
        currentSpeed = value
        applySpeed(value)
    end,
})

-- ================================================
-- TELEPORT TOOLS
-- ================================================

Tab:CreateSection("Teleport Tools")

local posLabel = Tab:CreateLabel("📍 Nenhuma posição guardada")

local function formatPosition(cf)
    local p = cf.Position
    return string.format("📍 Posição: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
end

Tab:CreateButton({
    Name     = "💾  Save Current Position",
    Callback = function()
        local character = LocalPlayer.Character
        local hrp       = character and character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Rayfield:Notify({ Title = "Erro", Content = "Personagem não encontrada.", Duration = 3 })
            return
        end

        savedCFrame = hrp.CFrame
        posLabel:Set(formatPosition(savedCFrame))

        Rayfield:Notify({
            Title   = "Posição Guardada!",
            Content = string.format("X: %.1f  Y: %.1f  Z: %.1f",
                savedCFrame.Position.X,
                savedCFrame.Position.Y,
                savedCFrame.Position.Z),
            Duration = 3,
        })
    end,
})

Tab:CreateButton({
    Name     = "🚀  Teleport to Saved Position",
    Callback = function()
        if not savedCFrame then
            Rayfield:Notify({
                Title   = "Sem Posição Guardada",
                Content = "Usa 'Save Current Position' primeiro.",
                Duration = 3.5,
            })
            return
        end

        local character = LocalPlayer.Character
        local hrp       = character and character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Rayfield:Notify({ Title = "Erro", Content = "Personagem não encontrada.", Duration = 3 })
            return
        end

        hrp.CFrame = savedCFrame

        Rayfield:Notify({
            Title   = "Teleportado!",
            Content = string.format("X: %.1f  Y: %.1f  Z: %.1f",
                savedCFrame.Position.X,
                savedCFrame.Position.Y,
                savedCFrame.Position.Z),
            Duration = 3,
        })
    end,
})

-- ================================================
-- AUTO COLLECT MONEY
-- ================================================

Tab:CreateSection("Auto Collect Money")

local moneyLabel = Tab:CreateLabel("💰 Auto Money: OFF  |  Recolhido: 0")

local function getMoneyRemote()
    local obj = game
    for _, key in ipairs(MONEY_REMOTE) do
        obj = obj:FindFirstChild(key)
        if not obj then return nil end
    end
    return obj
end

local function getMoneyFolder()
    return workspace:FindFirstChild(MONEY_FOLDER)
end

local function tryCollectMoney(moneyObj)
    local remote = getMoneyRemote()
    if remote then
        pcall(function() remote:FireServer(moneyObj) end)
        return
    end

    -- Alternativa: ProximityPrompt (descomenta se necessário)
    --[[
    local prompt = moneyObj:FindFirstChildOfClass("ProximityPrompt")
                or (moneyObj:IsA("Model") and moneyObj:FindFirstChildWhichIsA("ProximityPrompt", true))
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        return
    end
    ]]

    -- Alternativa: teleporte até à moeda (último recurso)
    --[[
    local hrp  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local part = moneyObj:IsA("BasePart") and moneyObj
              or (moneyObj:IsA("Model") and moneyObj:FindFirstChildWhichIsA("BasePart"))
    if hrp and part then
        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end
    ]]
end

local function startMoneyLoop()
    task.spawn(function()
        while autoMoneyEnabled do
            local character = LocalPlayer.Character
            local hrp       = character and character:FindFirstChild("HumanoidRootPart")
            local folder    = getMoneyFolder()

            if hrp and folder then
                for _, moneyObj in ipairs(folder:GetChildren()) do
                    if not autoMoneyEnabled then break end

                    local part = moneyObj:IsA("BasePart") and moneyObj
                              or (moneyObj:IsA("Model") and moneyObj:FindFirstChildWhichIsA("BasePart"))

                    if part then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist <= 60 then
                            tryCollectMoney(moneyObj)
                            moneyCount += 1
                            moneyLabel:Set("💰 Auto Money: ON  |  Recolhido: " .. moneyCount)
                            task.wait(0.15 + math.random() * 0.1)
                        end
                    end
                end
            end

            task.wait(moneyInterval)
        end

        moneyLabel:Set("💰 Auto Money: OFF  |  Recolhido: " .. moneyCount)
    end)
end

Tab:CreateToggle({
    Name         = "Auto Collect Money",
    CurrentValue = false,
    Flag         = "AutoMoneyToggle",
    Callback     = function(state)
        autoMoneyEnabled = state

        if state then
            Rayfield:Notify({
                Title   = "Auto Collect Money",
                Content = "Activado! A recolher dinheiro...",
                Duration = 3,
            })
            startMoneyLoop()
        else
            Rayfield:Notify({
                Title   = "Auto Collect Money",
                Content = "Desactivado.",
                Duration = 2.5,
            })
        end
    end,
})

Tab:CreateSlider({
    Name         = "Intervalo de recolha",
    Range        = {0.3, 3.0},
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = 1.0,
    Flag         = "MoneyIntervalSlider",
    Callback     = function(value)
        moneyInterval = value
    end,
})

-- ================================================
-- CONTROLOS
-- ================================================

Tab:CreateSection("Controlos")

Tab:CreateButton({
    Name     = "Destroy GUI",
    Callback = function()
        noclipEnabled    = false
        autoMoneyEnabled = false
        setNoclip(false)
        Rayfield:Destroy()
    end,
})

--[[
    Se o Auto Collect Money não funcionar:
    
    1. Usa Remote Spy e recolhe dinheiro manualmente.
       → Substitui MONEY_REMOTE pelo caminho real.
    
    2. No Explorer (Dex), procura a pasta no workspace
       onde as moedas aparecem.
       → Substitui MONEY_FOLDER pelo nome real.
    
    3. Se usar ProximityPrompt, descomenta a
       Alternativa 2 dentro de tryCollectMoney().
]]
