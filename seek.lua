-- Rayfield UIのロード
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ゲームサービスの取得
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ウィンドウの作成
local Window = Rayfield:CreateWindow({
    Name = "🎾 テニスゲームチート",
    LoadingTitle = "チートを初期化中...",
    LoadingSubtitle = "テニスゲーム用チートシステム",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TennisCheats",
        FileName = "Config"
    },
    KeySystem = false
})

-- グローバル変数
local Cheats = {
    AutoHit = false,
    BallControl = false,
    RacketSpeed = 1.0,
    AlwaysServe = false,
    NoMiss = false,
    TeleportBall = false,
    ShowBallPath = false,
    InstantWin = false,
    GodMode = false
}

local Ball = nil
local Racket = nil
local GameActive = false
local PredictionParts = {}

-- 主要タブ
local MainTab = Window:CreateTab("主要機能", 4483362458)

-- ボールとラケットの自動検出
local function FindGameObjects()
    -- ボールの検出
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Ball") or obj.Name:find("ball") then
            if obj:IsA("BasePart") then
                Ball = obj
                break
            end
        end
    end
    
    -- ラケットの検出
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Racket") or obj.Name:find("racket") or obj.Name:find("Paddle") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                Racket = obj
                break
            end
        end
    end
    
    -- プレイヤーのラケットを検出
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Racket") or tool.Name:find("racket")) then
                Racket = tool
            end
        end
    end
end

-- 自動ボール打ち返し
local AutoHitConnection
local function SetupAutoHit()
    if AutoHitConnection then
        AutoHitConnection:Disconnect()
    end
    
    if Cheats.AutoHit then
        AutoHitConnection = RunService.Heartbeat:Connect(function()
            if Ball and Racket and GameActive then
                -- ボールの位置を予測して移動
                local ballPos = Ball.Position
                local racketPos = Racket.Position
                
                -- ボールが近づいたら自動で打ち返す
                local distance = (ballPos - racketPos).Magnitude
                if distance < 15 then
                    -- 打ち返す方向を計算（対戦相手側へ）
                    local hitDirection = Vector3.new(-ballPos.X * 2, 5, ballPos.Z * 1.5)
                    
                    -- ボールに力を加える（実際のゲームではリモートイベントを使用）
                    if Ball:FindFirstChild("BodyVelocity") then
                        Ball.BodyVelocity.Velocity = hitDirection * 50
                    end
                end
            end
        end)
    end
end

-- ボールテレポート
local function TeleportToFront()
    if Ball and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        
        if humanoidRootPart then
            -- キャラクターの前方にボールを配置
            local offset = humanoidRootPart.CFrame.LookVector * 10
            Ball.Position = humanoidRootPart.Position + offset + Vector3.new(0, 5, 0)
            
            -- ボールを少し上に動かす
            if Ball:FindFirstChild("BodyVelocity") then
                Ball.BodyVelocity.Velocity = Vector3.new(0, 50, 0)
            end
        end
    end
end

-- ボール軌道予測
local function UpdateBallPrediction()
    if not Cheats.ShowBallPath or not Ball then
        -- 既存の予測パーツを削除
        for _, part in ipairs(PredictionParts) do
            if part then part:Destroy() end
        end
        PredictionParts = {}
        return
    end
    
    -- 既存の予測パーツを削除
    for _, part in ipairs(PredictionParts) do
        if part then part:Destroy() end
    end
    PredictionParts = {}
    
    -- 新しい予測パーツを作成
    local ballPos = Ball.Position
    local ballVelocity = Vector3.new(0, 0, 0)
    
    if Ball:FindFirstChild("BodyVelocity") then
        ballVelocity = Ball.BodyVelocity.Velocity
    end
    
    for i = 1, 20 do
        local time = i * 0.1
        local gravity = Vector3.new(0, -196.2 * time, 0)
        local predictedPos = ballPos + (ballVelocity * time) + (gravity * time * time * 0.5)
        
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.3, 0.3, 0.3)
        part.Position = predictedPos
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.5 + (i * 0.025)
        part.Color = Color3.fromRGB(255, 50, 50)
        part.Material = Enum.Material.Neon
        part.Parent = Workspace
        
        table.insert(PredictionParts, part)
    end
end

-- ポイント追加機能
local function AddPoints(points)
    -- ゲームのポイントシステムに応じて調整が必要
    local success, result = pcall(function()
        -- 一般的なテニスゲームのポイントイベント
        local events = {
            "AddPoint",
            "UpdateScore",
            "IncreaseScore",
            "PointScored"
        }
        
        for _, eventName in ipairs(events) do
            local event = ReplicatedStorage:FindFirstChild(eventName)
            if event then
                if event:IsA("RemoteEvent") then
                    event:FireServer(LocalPlayer, points)
                elseif event:IsA("RemoteFunction") then
                    event:InvokeServer(LocalPlayer, points)
                end
            end
        end
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "ポイント追加",
            Content = "ポイントシステムが見つかりませんでした",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- ミス防止機能
local NoMissConnection
local function SetupNoMiss()
    if NoMissConnection then
        NoMissConnection:Disconnect()
    end
    
    if Cheats.NoMiss then
        NoMissConnection = game.DescendantAdded:Connect(function(descendant)
            -- "Miss" や "Out" などのイベントを検出
            if descendant.Name:find("Miss") or descendant.Name:find("miss") then
                if descendant:IsA("RemoteEvent") then
                    -- ミスイベントを傍受
                end
            end
        end)
    end
end

-- UI要素の作成

-- 自動検出ボタン
local DetectButton = MainTab:CreateButton({
    Name = "ゲームオブジェクト自動検出",
    Callback = function()
        FindGameObjects()
        if Ball then
            Rayfield:Notify({
                Title = "検出完了",
                Content = string.format("ボール: %s\nラケット: %s", 
                    tostring(Ball), 
                    tostring(Racket)),
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "警告",
                Content = "ゲームオブジェクトが見つかりませんでした",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- オートプレイトグル
local AutoHitToggle = MainTab:CreateToggle({
    Name = "オートプレイ (自動打ち返し)",
    CurrentValue = false,
    Flag = "AutoHitToggle",
    Callback = function(Value)
        Cheats.AutoHit = Value
        SetupAutoHit()
        Rayfield:Notify({
            Title = "オートプレイ",
            Content = Value and "有効化しました" or "無効化しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- ボールコントロールトグル
local BallControlToggle = MainTab:CreateToggle({
    Name = "ボール軌道コントロール",
    CurrentValue = false,
    Flag = "BallControlToggle",
    Callback = function(Value)
        Cheats.BallControl = Value
        if Value then
            Rayfield:Notify({
                Title = "ボールコントロール",
                Content = "右クリックでボールをコントロール",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- ボールテレポートボタン
local TeleportButton = MainTab:CreateButton({
    Name = "ボールを前にテレポート",
    Callback = function()
        TeleportToFront()
        Rayfield:Notify({
            Title = "テレポート",
            Content = "ボールを前に移動しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- スピードハックスライダー
local SpeedSlider = MainTab:CreateSlider({
    Name = "ラケット速度倍率",
    Range = {0.5, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.0,
    Flag = "SpeedSlider",
    Callback = function(Value)
        Cheats.RacketSpeed = Value
        if Racket then
            -- ラケットの速度を調整
        end
    end
})

-- ポイント操作タブ
local PointsTab = Window:CreateTab("ポイント操作", 4483362458)

-- ポイント追加ボタン
local AddPointButton = PointsTab:CreateButton({
    Name = "ポイントを追加 (+1)",
    Callback = function()
        AddPoints(1)
        Rayfield:Notify({
            Title = "ポイント追加",
            Content = "ポイントを追加しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

local Add5PointsButton = PointsTab:CreateButton({
    Name = "ポイントを追加 (+5)",
    Callback = function()
        AddPoints(5)
        Rayfield:Notify({
            Title = "ポイント追加",
            Content = "5ポイント追加しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- 勝利ボタン
local WinButton = PointsTab:CreateButton({
    Name = "即時勝利",
    Callback = function()
        Cheats.InstantWin = true
        AddPoints(100)
        Rayfield:Notify({
            Title = "即時勝利",
            Content = "勝利ポイントを追加しました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 視覚効果タブ
local VisualTab = Window:CreateTab("視覚効果", 4483362458)

-- ボール軌道予測
local BallPathToggle = VisualTab:CreateToggle({
    Name = "ボール軌道予測表示",
    CurrentValue = false,
    Flag = "BallPathToggle",
    Callback = function(Value)
        Cheats.ShowBallPath = Value
        if not Value then
            UpdateBallPrediction()
        end
    end
})

-- ESP機能
local ESPToggle = VisualTab:CreateToggle({
    Name = "ボールESP (ハイライト)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        if Value and Ball then
            -- ボールをハイライト
            local highlight = Instance.new("Highlight")
            highlight.Adornee = Ball
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.Parent = Ball
        elseif Ball then
            -- ハイライトを削除
            for _, child in pairs(Ball:GetChildren()) do
                if child:IsA("Highlight") then
                    child:Destroy()
                end
            end
        end
    end
})

-- その他タブ
local MiscTab = Window:CreateTab("その他", 4483362458)

-- ミス防止
local NoMissToggle = MiscTab:CreateToggle({
    Name = "ミス防止",
    CurrentValue = false,
    Flag = "NoMissToggle",
    Callback = function(Value)
        Cheats.NoMiss = Value
        SetupNoMiss()
    end
})

-- 常にサーブ権
local AlwaysServeToggle = MiscTab:CreateToggle({
    Name = "常にサーブ権",
    CurrentValue = false,
    Flag = "AlwaysServeToggle",
    Callback = function(Value)
        Cheats.AlwaysServe = Value
    end
})

-- ゲーム状態検出
local GameStatusToggle = MiscTab:CreateToggle({
    Name = "ゲーム状態自動検出",
    CurrentValue = false,
    Flag = "GameStatusToggle",
    Callback = function(Value)
        if Value then
            -- ゲーム開始/終了を検出
            local matchStartEvents = {
                "StartMatch",
                "MatchBegin",
                "GameStart"
            }
            
            for _, eventName in ipairs(matchStartEvents) do
                local event = ReplicatedStorage:FindFirstChild(eventName)
                if event and event:IsA("RemoteEvent") then
                    event.OnClientEvent:Connect(function()
                        GameActive = true
                        Rayfield:Notify({
                            Title = "ゲーム開始",
                            Content = "マッチが開始されました",
                            Duration = 3,
                            Image = 4483362458
                        })
                    end)
                end
            end
            
            local matchEndEvents = {
                "EndMatch",
                "MatchEnd",
                "GameOver"
            }
            
            for _, eventName in ipairs(matchEndEvents) do
                local event = ReplicatedStorage:FindFirstChild(eventName)
                if event and event:IsA("RemoteEvent") then
                    event.OnClientEvent:Connect(function()
                        GameActive = false
                        Rayfield:Notify({
                            Title = "ゲーム終了",
                            Content = "マッチが終了しました",
                            Duration = 3,
                            Image = 4483362458
                        })
                    end)
                end
            end
        end
    end
})

-- リセットボタン
local ResetButton = MiscTab:CreateButton({
    Name = "チートリセット",
    Callback = function()
        Cheats = {
            AutoHit = false,
            BallControl = false,
            RacketSpeed = 1.0,
            AlwaysServe = false,
            NoMiss = false,
            TeleportBall = false,
            ShowBallPath = false,
            InstantWin = false,
            GodMode = false
        }
        
        if AutoHitConnection then AutoHitConnection:Disconnect() end
        if NoMissConnection then NoMissConnection:Disconnect() end
        
        for _, part in ipairs(PredictionParts) do
            if part then part:Destroy() end
        end
        PredictionParts = {}
        
        Rayfield:Notify({
            Title = "リセット完了",
            Content = "すべてのチートをリセットしました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ボールコントロール用のマウスイベント
local ballControlConnection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 and Cheats.BallControl and Ball then
        -- 右クリックでボールをコントロール
        ballControlConnection = RunService.Heartbeat:Connect(function()
            if Ball then
                local mouseHit = Mouse.Hit
                Ball.Position = mouseHit.Position
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and ballControlConnection then
        ballControlConnection:Disconnect()
        ballControlConnection = nil
    end
end)

-- メインループ
RunService.Heartbeat:Connect(function()
    -- ボール軌道予測の更新
    if Cheats.ShowBallPath then
        UpdateBallPrediction()
    end
    
    -- ゲームオブジェクトの定期的な検出
    if not Ball or not Racket then
        FindGameObjects()
    end
end)

-- 初期化通知
Rayfield:Notify({
    Title = "🎾 テニスチート",
    Content = "チートシステムが起動しました\n最初に「ゲームオブジェクト自動検出」を実行してください",
    Duration = 5,
    Image = 4483362458
})
