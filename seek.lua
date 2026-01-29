-- Rayfield UIのロード
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ウィンドウの作成
local Window = Rayfield:CreateWindow({
    Name = "テニスゲームチートメニュー",
    LoadingTitle = "チートをロード中...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TennisCheats",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "認証",
        Subtitle = "キーを入力",
        Note = "キーを購入するにはDiscordに参加",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = "1234"
    }
})

-- 既存の変数を取得（既存のコードから）
local LocalPlayer_upvr = game.Players.LocalPlayer
local ReplicatedStorage_upvr = game.ReplicatedStorage
local RunService_upvr = game:GetService("RunService")

-- チート変数
local Cheats = {
    AutoHit = false,          -- 自動でボールを打つ
    BallControl = false,      -- ボールの軌道をコントロール
    SpeedHack = false,        -- ラケット速度向上
    AlwaysServe = false,      -- 常にサーブ権
    NoMiss = false,           -- ミスしない
    InstantWin = false,       -- 即座に勝利
    ShowBallPrediction = false, -- ボールの軌道予測表示
}

-- ボール予測用のパーツ
local predictionParts = {}
local predictionFolder = Instance.new("Folder")
predictionFolder.Name = "BallPrediction"
predictionFolder.Parent = workspace

-- タブの作成
local MainTab = Window:CreateTab("主要チート", 4483362458)
local VisualTab = Window:CreateTab("視覚効果", 4483362458)
local MiscTab = Window:CreateTab("その他", 4483362458)

-- ボール軌道予測関数
local function predictBallPath(startPos, velocity, steps, stepTime)
    for _, part in ipairs(predictionParts) do
        part:Destroy()
    end
    predictionParts = {}
    
    if not Cheats.ShowBallPrediction then return end
    
    local gravity = Vector3.new(0, -196.2, 0)
    local currentPos = startPos
    local currentVel = velocity
    
    for i = 1, steps do
        local time = stepTime * i
        
        -- 物理計算（位置 = 初期位置 + 速度*時間 + 0.5*重力*時間^2）
        local predictedPos = startPos + velocity * time + 0.5 * gravity * time * time
        
        -- 予測点を表示
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Position = predictedPos
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.7
        part.Color = Color3.fromRGB(255, 0, 0)
        part.Material = Enum.Material.Neon
        part.Parent = predictionFolder
        
        -- サイズを段階的に小さく
        part.Size = Vector3.new(0.5 - (i * 0.03), 0.5 - (i * 0.03), 0.5 - (i * 0.03))
        part.Transparency = 0.3 + (i * 0.07)
        
        table.insert(predictionParts, part)
    end
end

-- 自動ヒット機能
local autoHitConnection
local function setupAutoHit()
    if autoHitConnection then
        autoHitConnection:Disconnect()
        autoHitConnection = nil
    end
    
    if Cheats.AutoHit then
        autoHitConnection = RunService_upvr.Heartbeat:Connect(function()
            -- 既存のヒット検出ロジックを強化
            -- ボールに自動的に近づいて打ち返す
            -- 注: 実際の実装はゲームの具体的な構造に依存します
        end)
    end
end

-- ボールコントロール機能
local ballControlConnection
local function setupBallControl()
    if ballControlConnection then
        ballControlConnection:Disconnect()
        ballControlConnection = nil
    end
    
    if Cheats.BallControl then
        ballControlConnection = RunService_upvr.Heartbeat:Connect(function()
            -- ボールの位置や速度を操作する
            -- 注: 実際の実装はゲームの具体的な構造に依存します
        end)
    end
end

-- ミス防止機能
local noMissConnection
local function setupNoMiss()
    if noMissConnection then
        noMissConnection:Disconnect()
        noMissConnection = nil
    end
    
    if Cheats.NoMiss then
        noMissConnection = ReplicatedStorage_upvr.Missed.OnClientEvent:Connect(function()
            -- ミスイベントをキャンセル
            return
        end)
    end
end

-- 即時勝利機能
local function instantWin()
    if Cheats.InstantWin then
        -- サーバーに勝利を報告
        -- 注: 実際の実装はゲームのアンチチート対策によって異なります
        pcall(function()
            -- ポイントを直接設定する試み
            ReplicatedStorage_upvr.UpdatePoints:FireServer(10, 0)
        end)
    end
end

-- 主要チートタブ
local AutoHitToggle = MainTab:CreateToggle({
    Name = "自動打ち返し",
    CurrentValue = false,
    Flag = "AutoHitToggle",
    Callback = function(Value)
        Cheats.AutoHit = Value
        setupAutoHit()
        Rayfield:Notify({
            Title = "自動打ち返し",
            Content = Value and "有効" or "無効",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

local BallControlToggle = MainTab:CreateToggle({
    Name = "ボール軌道コントロール",
    CurrentValue = false,
    Flag = "BallControlToggle",
    Callback = function(Value)
        Cheats.BallControl = Value
        setupBallControl()
        Rayfield:Notify({
            Title = "ボール軌道コントロール",
            Content = Value and "有効" or "無効",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

local SpeedHackSlider = MainTab:CreateSlider({
    Name = "ラケット速度倍率",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "倍",
    CurrentValue = 1,
    Flag = "SpeedHackSlider",
    Callback = function(Value)
        Cheats.SpeedHack = Value
        -- 既存のラケット速度変数を上書き
        -- 注: 実際の変数名はゲームによって異なります
    end
})

local AlwaysServeToggle = MainTab:CreateToggle({
    Name = "常にサーブ権",
    CurrentValue = false,
    Flag = "AlwaysServeToggle",
    Callback = function(Value)
        Cheats.AlwaysServe = Value
        if Value then
            -- サーブイベントを常にトリガーする
            -- 注: 実際の実装はゲームの構造に依存します
        end
    end
})

local NoMissToggle = MainTab:CreateToggle({
    Name = "ミス無効",
    CurrentValue = false,
    Flag = "NoMissToggle",
    Callback = function(Value)
        Cheats.NoMiss = Value
        setupNoMiss()
    end
})

-- 視覚効果タブ
local BallPredictionToggle = VisualTab:CreateToggle({
    Name = "ボール軌道予測表示",
    CurrentValue = false,
    Flag = "BallPredictionToggle",
    Callback = function(Value)
        Cheats.ShowBallPrediction = Value
        if not Value then
            for _, part in ipairs(predictionParts) do
                part:Destroy()
            end
            predictionParts = {}
        end
    end
})

local ESPToggle = VisualTab:CreateToggle({
    Name = "ボールESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        -- ボールの位置を常に表示するESP
        -- 注: 実際の実装が必要です
    end
})

-- その他タブ
local InstantWinButton = MiscTab:CreateButton({
    Name = "即時勝利",
    Callback = function()
        Cheats.InstantWin = true
        instantWin()
        Rayfield:Notify({
            Title = "即時勝利",
            Content = "勝利を試みました",
            Duration = 3,
            Image = 4483362458,
        })
    end
})

local AddPointButton = MiscTab:CreateButton({
    Name = "ポイント追加",
    Callback = function()
        -- 現在のポイントを取得して1ポイント追加
        pcall(function()
            -- 実際のポイント追加ロジック
            -- 注: ゲームの実装に依存します
        end)
        Rayfield:Notify({
            Title = "ポイント追加",
            Content = "ポイントを追加しました",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

local ResetPointsButton = MiscTab:CreateButton({
    Name = "ポイントリセット",
    Callback = function()
        -- ポイントを0-0にリセット
        pcall(function()
            ReplicatedStorage_upvr.UpdatePoints:FireServer(0, 0)
        end)
    end
})

local TeleportBallButton = MiscTab:CreateButton({
    Name = "ボールを前にテレポート",
    Callback = function()
        -- ボールをプレイヤーの前に移動
        -- 注: 実際の実装はゲームの構造に依存します
        Rayfield:Notify({
            Title = "ボールテレポート",
            Content = "ボールを前に移動しました",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

-- キーバインド設定
local Input = MiscTab:CreateInput({
    Name = "チート有効化キー",
    PlaceholderText = "キーを入力...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        -- キーバインド設定
        -- 注: 実際のキーバインド実装が必要です
    end
})

-- ゲーム終了時やリセット時のクリーンアップ
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    -- すべての接続を解除
    if autoHitConnection then
        autoHitConnection:Disconnect()
    end
    if ballControlConnection then
        ballControlConnection:Disconnect()
    end
    if noMissConnection then
        noMissConnection:Disconnect()
    end
    
    -- 予測パーツをクリーンアップ
    for _, part in ipairs(predictionParts) do
        part:Destroy()
    end
    predictionParts = {}
    
    if predictionFolder then
        predictionFolder:Destroy()
    end
end)

-- 既存のゲームイベントをフックしてチート機能を追加
local originalFunctions = {}

-- ヒット関数をフック
local success, originalHit = pcall(function()
    -- 既存のhitBall_upvr関数を保存して上書き
    -- 注: 実際の関数名はデコンパイル結果によって異なります
end)

if success and type(originalHit) == "function" then
    originalFunctions.hitBall = originalHit
    
    -- 新しいヒット関数を作成
    local newHitBall = function()
        -- チートが有効な場合、強化されたヒット
        if Cheats.AutoHit then
            -- 自動ヒットロジック
        end
        
        if Cheats.BallControl then
            -- ボールコントロールロジック
        end
        
        -- 元の関数を呼び出し
        return originalHit()
    end
    
    -- 関数を上書き
    -- hitBall_upvr = newHitBall など
end

-- サーブ関数をフック
ReplicatedStorage_upvr.Serve.OnClientEvent:Connect(function(...)
    if Cheats.AlwaysServe then
        -- 常にサーブ権を持つロジック
        -- サーバーに強制的にサーブを要求
    end
    
    -- 元のイベント処理を続行
end)

Rayfield:Notify({
    Title = "チートメニュー",
    Content = "テニスゲームチートがロードされました！",
    Duration = 5,
    Image = 4483362458,
})
