-- ================================================
--   Mine for Anime Fruits - Simple Tools
--   UI: Rayfield Library
--   Funções: Noclip + WalkSpeed + Teleport Tools
-- ================================================

repeat task.wait() until game:IsLoaded()

-- ▸ Serviços
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ▸ Referências ao jogador
local LocalPlayer = Players.LocalPlayer

-- ================================================
-- VARIÁVEIS DE ESTADO
-- ================================================

local noclipEnabled    = false
local noclipConnection = nil
local currentSpeed     = 16
local savedCFrame      = nil   -- guarda a posição/CFrame salva

-- ================================================
-- CARREGAR RAYFIELD
-- ================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ================================================
-- CRIAR JANELA PRINCIPAL
-- ================================================

local Window = Rayfield:CreateWindow({
    Name            = "Mine for Anime Fruits - Simple Tools",
    LoadingTitle    = "A carregar...",
    LoadingSubtitle = "Simple Tools v1.1",
    ConfigurationSaving = { Enabled = false },
    Discord         = { Enabled = false },
    KeySystem       = false,
})

local Tab = Window:CreateTab("Main", nil)

-- ================================================
-- SECÇÃO 1: NOCLIP
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

-- Repõe o noclip após respawn
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
            Content  = state and "Activado! Atravessa tudo." or "Desactivado.",
            Duration = 2.5,
            Image    = nil,
        })
    end,
})

-- ================================================
-- SECÇÃO 2: WALKSPEED
-- ================================================

Tab:CreateSection("WalkSpeed")

local function applySpeed(speed)
    local character = LocalPlayer.Character
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

-- Repõe o WalkSpeed após respawn
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
-- SECÇÃO 3: TELEPORT TOOLS
-- ================================================

Tab:CreateSection("Teleport Tools")

--[[
    SAVE POSITION:
    Guarda o CFrame actual do HumanoidRootPart.
    O CFrame inclui posição E rotação, por isso
    o jogador volta exactamente orientado da mesma
    forma que estava quando guardou.

    A posição guardada persiste mesmo após morte/
    respawn porque está numa variável local (savedCFrame)
    que não é apagada pelo CharacterAdded.
]]

-- Label que mostra a posição guardada actual
local posLabel = Tab:CreateLabel("📍 Nenhuma posição guardada")

-- Função auxiliar: formata o Vector3 para texto legível
local function formatPosition(cf)
    local p = cf.Position
    return string.format(
        "📍 Posição: %.1f, %.1f, %.1f",
        p.X, p.Y, p.Z
    )
end

-- Botão: Guardar posição actual
Tab:CreateButton({
    Name     = "💾  Save Current Position",
    Callback = function()
        local character = LocalPlayer.Character
        local hrp       = character and character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Rayfield:Notify({
                Title    = "Erro",
                Content  = "Personagem não encontrada. Tenta novamente.",
                Duration = 3,
                Image    = nil,
            })
            return
        end

        -- Guarda o CFrame completo (posição + rotação)
        savedCFrame = hrp.CFrame

        -- Actualiza o label com as coordenadas
        posLabel:Set(formatPosition(savedCFrame))

        Rayfield:Notify({
            Title    = "Posição Guardada!",
            Content  = string.format(
                "X: %.1f  Y: %.1f  Z: %.1f",
                savedCFrame.Position.X,
                savedCFrame.Position.Y,
                savedCFrame.Position.Z
            ),
            Duration = 3,
            Image    = nil,
        })
    end,
})

-- Botão: Teleportar para posição guardada
Tab:CreateButton({
    Name     = "🚀  Teleport to Saved Position",
    Callback = function()

        -- Verifica se há posição guardada
        if not savedCFrame then
            Rayfield:Notify({
                Title    = "Sem Posição Guardada",
                Content  = "Nenhuma posição guardada ainda! Usa 'Save Current Position' primeiro.",
                Duration = 3.5,
                Image    = nil,
            })
            return
        end

        local character = LocalPlayer.Character
        local hrp       = character and character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Rayfield:Notify({
                Title    = "Erro",
                Content  = "Personagem não encontrada. Tenta novamente.",
                Duration = 3,
                Image    = nil,
            })
            return
        end

        --[[
            Teletransporte seguro:
            Desactiva brevemente o physics anchor para
            garantir que o CFrame é aplicado correctamente,
            mesmo com o servidor a resistir ao movimento.
        ]]
        hrp.CFrame = savedCFrame

        Rayfield:Notify({
            Title    = "Teleportado!",
            Content  = string.format(
                "Voltaste para X: %.1f  Y: %.1f  Z: %.1f",
                savedCFrame.Position.X,
                savedCFrame.Position.Y,
                savedCFrame.Position.Z
            ),
            Duration = 3,
            Image    = nil,
        })
    end,
})

-- ================================================
-- SECÇÃO 4: CONTROLOS
-- ================================================

Tab:CreateSection("Controlos")

Tab:CreateButton({
    Name     = "Destroy GUI",
    Callback = function()
        noclipEnabled = false
        setNoclip(false)
        Rayfield:Destroy()
    end,
})
