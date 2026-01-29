-- Roblox Tennis Exploit / Mod Menu using Rayfield UI
-- 注意: このスクリプトは教育目的・学習目的でのみ使用してください。
--       実際のゲームで不正使用するとアカウント停止のリスクがあります。

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Tennis Mod Menu",
    LoadingTitle = "Tennis Client Enhancements",
    LoadingSubtitle = "by Grok • 2026",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "TennisMod"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458) -- アイコンID例
local AutoSection = MainTab:CreateSection("Automation")
local PowerSection = MainTab:CreateSection("Power & Combo")
local VisualSection = MainTab:CreateSection("Visual / Misc")

-- 元スクリプトから重要なupvalueを参照しようとするが、直接アクセス困難なため
-- 代わりにインスタンス・リモート経由で操作するアプローチを採用

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- リモートイベント（元スクリプトより推測）
local HitBallReplication = ReplicatedStorage:WaitForChild("HitBallReplication", 8)
local ServeEvent = ReplicatedStorage:WaitForChild("Serve", 8)
local MissedEvent = ReplicatedStorage:WaitForChild("Missed", 8)
local ChangePosition = ReplicatedStorage:WaitForChild("ChangePosition", 8)

-- 自動ヒット用変数
local AutoHitEnabled = false
local HitboxMultiplier = 1.0
local PowerOverride = nil
local AlwaysServe = false
local RacketSpeedMult = 1.0

-- ラケット（var12_upvw）の検知部分をフックしようとする試み
local racketDetectionPart = nil

-- 最もらしいラケットのdetectionを探す（初回StartMatch後）
local function FindRacketDetection()
    if LocalPlayer.Character then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Name == "detection" and obj.Parent and obj.Parent:IsDescendantOf(LocalPlayer.Character) then
                racketDetectionPart = obj
                return obj
            end
        end
    end
    return nil
end

-- Auto Hit ループ
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not AutoHitEnabled then return end
        
        local ball = workspace:FindFirstChild("ClientBall") or workspace:FindFirstChildWhichIsA("BasePart", true) -- 仮
        if not ball then return end
        
        if racketDetectionPart then
            local dist = (racketDetectionPart.Position - ball.Position).Magnitude
            local expandedSize = racketDetectionPart.Size * HitboxMultiplier
            
            if dist < (expandedSize.Magnitude / 2 + ball.Size.Magnitude / 2 + 2) then
                -- hitBall_upvr を模倣して発火
                if HitBallReplication then
                    -- 実際の引数はゲームによって異なるが、位置と軌道情報を送る形が多い
                    local fakeTrajectory = {ball.Position, ball.Position + Vector3.new(0,10,0), ball.Position + Vector3.new(0,20,0), 1}
                    HitBallReplication:FireServer(ball.Position, fakeTrajectory, false)
                end
                
                -- 音を鳴らす（任意）
                if game.SoundService:FindFirstChild("RacketHit") then
                    game.SoundService.RacketHit:Play()
                end
            end
        end
    end)
end)

-- UI 作成

AutoSection:CreateToggle({
    Name = "Auto Hit (Auto Swing)",
    CurrentValue = false,
    Flag = "AutoHit",
    Callback = function(Value)
        AutoHitEnabled = Value
        
        -- detectionパートを探す
        if Value and not racketDetectionPart then
            racketDetectionPart = FindRacketDetection()
            if not racketDetectionPart then
                Rayfield:Notify({
                    Title = "Warning",
                    Content = "Racket detection part not found yet. Wait for match start.",
                    Duration = 4,
                })
            end
        end
    end,
})

AutoSection:CreateSlider({
    Name = "Hitbox Expander Multiplier",
    Range = {1, 6},
    Increment = 0.2,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "HitboxExp",
    Callback = function(Value)
        HitboxMultiplier = Value
        
        -- 見つかれば即時適用
        if racketDetectionPart then
            racketDetectionPart.Size = racketDetectionPart.Size * Value  -- 注意：見た目が変わる可能性あり
        end
    end,
})

AutoSection:CreateButton({
    Name = "Force Serve (Now)",
    Callback = function()
        if ServeEvent then
            ServeEvent:FireServer()  -- 引数なしで呼ぶゲームが多い
            Rayfield:Notify({Title = "Serve", Content = "Serve forced.", Duration = 2})
        else
            Rayfield:Notify({Title = "Error", Content = "Serve remote not found.", Duration = 4})
        end
    end,
})

PowerSection:CreateToggle({
    Name = "Always Serve (Try to keep serve)",
    CurrentValue = false,
    Flag = "AlwaysServe",
    Callback = function(Value)
        AlwaysServe = Value
        -- var16_upvw を直接操作できないため、Serveイベントをフックするか擬似的に再サーブ
    end,
})

PowerSection:CreateInput({
    Name = "Set Combo / Power Level",
    PlaceholderText = "10 = max power etc",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            PowerOverride = num
            Rayfield:Notify({Title = "Power", Content = "Set to "..num.." (if game allows)", Duration = 3})
        end
    end,
})

VisualSection:CreateSlider({
    Name = "Racket Move Speed Multiplier",
    Range = {0.5, 4},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "RacketSpeed",
    Callback = function(Value)
        RacketSpeedMult = Value
        -- AlignPositionのResponsivenessを変更したいが特定困難 → 後で実装可能なら
    end,
})

VisualSection:CreateParagraph({
    Title = "Current Status (approximate)",
    Content = "Auto Hit: "..tostring(AutoHitEnabled).."\nHitbox Mult: "..HitboxMultiplier.."\nPower Override: "..tostring(PowerOverride or "default"),
})

Rayfield:Notify({
    Title = "Loaded",
    Content = "Tennis mod menu initialized.\nSome features may require active match.",
    Duration = 6.5,
    Image = 4483362458,
})

-- 試合開始時にdetectionパートを再検索
if ReplicatedStorage:FindFirstChild("StartMatch") then
    ReplicatedStorage.StartMatch.OnClientEvent:Connect(function()
        task.wait(1.5)
        racketDetectionPart = FindRacketDetection()
    end)
end
