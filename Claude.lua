-- Rayfield UIのロード
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 必要なサービスとプレイヤー情報
local LocalPlayer = game.Players.LocalPlayer
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")

-- 設定用の変数
local Settings = {
    AutoPlay = false,
    RacketSpeed = 1,
    BallSpeed = 1,
    AlwaysServe = false,
    CustomTrajectory = false,
    TrajectoryHeight = 4
}

-- ウィンドウの作成
local Window = Rayfield:CreateWindow({
    Name = "Tennis Game Mod Menu",
    LoadingTitle = "Tennis Mod Loading...",
    LoadingSubtitle = "by Script Creator",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TennisMod",
        FileName = "TennisConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- メインタブ
local MainTab = Window:CreateTab("メイン機能", 4483362458)
local SettingsTab = Window:CreateTab("設定", 4483345737)

-- オートプレイセクション
local AutoPlaySection = MainTab:CreateSection("オートプレイ")

local AutoPlayToggle = MainTab:CreateToggle({
    Name = "オートプレイを有効化",
    CurrentValue = false,
    Flag = "AutoPlayToggle",
    Callback = function(Value)
        Settings.AutoPlay = Value
        if Value then
            Rayfield:Notify({
                Title = "オートプレイ",
                Content = "自動打ち返しが有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- ラケット速度セクション
local RacketSection = MainTab:CreateSection("ラケット設定")

local RacketSpeedSlider = MainTab:CreateSlider({
    Name = "ラケット移動速度",
    Range = {1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "RacketSpeed",
    Callback = function(Value)
        Settings.RacketSpeed = Value
    end,
})

-- ボール軌道セクション
local BallSection = MainTab:CreateSection("ボール設定")

local CustomTrajectoryToggle = MainTab:CreateToggle({
    Name = "カスタム軌道を有効化",
    CurrentValue = false,
    Flag = "CustomTrajectory",
    Callback = function(Value)
        Settings.CustomTrajectory = Value
    end,
})

local TrajectoryHeightSlider = MainTab:CreateSlider({
    Name = "ボールの軌道の高さ",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "m",
    CurrentValue = 4,
    Flag = "TrajectoryHeight",
    Callback = function(Value)
        Settings.TrajectoryHeight = Value
    end,
})

local BallSpeedSlider = MainTab:CreateSlider({
    Name = "ボールの速度倍率",
    Range = {0.5, 3},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "BallSpeed",
    Callback = function(Value)
        Settings.BallSpeed = Value
    end,
})

-- サーブ設定セクション
local ServeSection = MainTab:CreateSection("サーブ設定")

local AlwaysServeToggle = MainTab:CreateToggle({
    Name = "常にサーブ権を持つ",
    CurrentValue = false,
    Flag = "AlwaysServe",
    Callback = function(Value)
        Settings.AlwaysServe = Value
        if Value then
            Rayfield:Notify({
                Title = "サーブ権",
                Content = "常にサーブ権を持つようになりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- ポイント変更セクション
local PointSection = SettingsTab:CreateSection("ポイント変更")

local SetPointsButton = SettingsTab:CreateButton({
    Name = "自分のポイントを最大にする",
    Callback = function()
        -- サーバー側で管理されている可能性があるため、
        -- クライアント側のUI表示のみ変更
        pcall(function()
            LocalPlayer.PlayerGui.Main.HUD.MatchInfo.MainFrame.Score1.TextLabel.Text = "99"
        end)
        Rayfield:Notify({
            Title = "ポイント変更",
            Content = "ポイント表示を変更しました（表示のみ）",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- リセットボタン
local ResetSection = SettingsTab:CreateSection("リセット")

local ResetButton = SettingsTab:CreateButton({
    Name = "すべての設定をリセット",
    Callback = function()
        Settings.AutoPlay = false
        Settings.RacketSpeed = 1
        Settings.BallSpeed = 1
        Settings.AlwaysServe = false
        Settings.CustomTrajectory = false
        Settings.TrajectoryHeight = 4
        
        Rayfield:Notify({
            Title = "リセット完了",
            Content = "すべての設定がデフォルトに戻りました",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- オートプレイ機能の実装
local function AutoPlayFunction()
    if not Settings.AutoPlay then return end
    
    -- ボールとラケットの参照を取得
    local ball = workspace:FindFirstChild("ClientBall")
    local racket = workspace:FindFirstChild("Racket") or LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    
    if ball and racket then
        -- ボールがプレイヤー側に来ているか確認
        local ballPos = ball.Position
        local racketPos = racket:FindFirstChild("Handle") and racket.Handle.Position or Vector3.new()
        
        -- ボールとの距離を計算
        local distance = (ballPos - racketPos).Magnitude
        
        -- 一定距離内なら自動で打つ
        if distance < 10 then
            -- hitBall関数を呼び出す（元のスクリプトから）
            ReplicatedStorage.HitBall:FireServer()
        end
    end
end

-- ラケット速度調整の実装
local originalMouseMove
local function ModifyRacketSpeed()
    if Settings.RacketSpeed == 1 then return end
    
    -- マウス移動イベントをフック
    local mouse = LocalPlayer:GetMouse()
    mouse.Move:Connect(function()
        -- ラケットの移動速度を調整
        if workspace:FindFirstChild("Racket") then
            local racket = workspace.Racket
            if racket:FindFirstChild("AlignPosition") then
                racket.AlignPosition.MaxVelocity = 50 * Settings.RacketSpeed
            end
        end
    end)
end

-- ボール軌道変更の実装
local function ModifyBallTrajectory()
    if not Settings.CustomTrajectory then return end
    
    -- getMidPoint関数をオーバーライド
    local oldGetMidPoint = getrawmetatable(game).__namecall
    setreadonly(getrawmetatable(game), false)
    
    getrawmetatable(game).__namecall = newcclosure(function(...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "getMidPoint" and Settings.CustomTrajectory then
            local arg1, arg2 = args[1], args[2]
            return (arg2 + arg1) / 2 + Vector3.new(0, Settings.TrajectoryHeight, 0)
        end
        
        return oldGetMidPoint(...)
    end)
    
    setreadonly(getrawmetatable(game), true)
end

-- 常にサーブ権を持つ機能
ReplicatedStorage.Serve.OnClientEvent:Connect(function()
    if Settings.AlwaysServe then
        wait(0.1)
        -- サーブを強制的に実行
        ReplicatedStorage.Serve:Fire()
    end
end)

-- メインループ
RunService.Heartbeat:Connect(function()
    AutoPlayFunction()
end)

-- 初期化通知
Rayfield:Notify({
    Title = "Tennis Mod Menu",
    Content = "正常に読み込まれました！",
    Duration = 5,
    Image = 4483362458
})

-- UI表示
Rayfield:LoadConfiguration()
