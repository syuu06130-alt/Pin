-- Rayfield UI をロード（ユーザーが指定したURLを使用）
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "PingPong! Client Tools",
   LoadingTitle = "PingPong Client Mod",
   LoadingSubtitle = "by 羽 | Status: Decompiled & Patched",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "PingPongClientMod",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = true
   },
   KeySystem = false
})

-- メインタブ
local MainTab = Window:CreateTab("Main Controls", 4483362458) -- アイコンID例

-- 状態表示グループ
local StatusGroup = MainTab:CreateSection("Game Status")

MainTab:CreateLabel("Hit Count (Combo): Loading...")
MainTab:CreateLabel("Serve Ready: Loading...")
MainTab:CreateLabel("Side (1=Left / -1=Right): Loading...")

-- 定期更新（Heartbeatで状態を監視）
task.spawn(function()
   while true do
      task.wait(0.4)
      
      local hitCount = getrenv().var20_upvw or "N/A"
      local isServe = getrenv().var15_upvw and "Yes" or "No"
      local side = getrenv().var9_upvw or "N/A"
      
      -- RayfieldのLabelは直接更新できないので、必要に応じて再作成 or Paragraph使用
      -- ここでは簡易的にPrintで代用（本番ではParagraph推奨）
      print(string.format("Hits: %s | Serve: %s | Side: %s", hitCount, isServe, side))
   end
end)

-- 操作グループ
local ActionGroup = MainTab:CreateSection("Actions")

ActionGroup:CreateButton({
   Name = "Force Serve (if possible)",
   Callback = function()
      if ReplicatedStorage_upvr and ReplicatedStorage_upvr:FindFirstChild("Serve") then
         -- 直接Fireはセキュリティでブロックされる可能性が高い
         -- 代わりに内部変数を操作して擬似サーブ
         getrenv().var18_upvw = true
         getrenv().var20_upvw = 0
         getrenv().var17_upvw = true
         getrenv().var15_upvw = true
         getrenv().var16_upvw = true
         Rayfield:Notify({
            Title = "Force Serve",
            Content = "Internal flags reset → try hitting ball",
            Duration = 4,
         })
      end
   end,
})

ActionGroup:CreateButton({
   Name = "Reset Hit Counter",
   Callback = function()
      getrenv().var20_upvw = 0
      Rayfield:Notify({Title = "Reset", Content = "Combo / Hit counter cleared", Duration = 3})
   end,
})

ActionGroup:CreateToggle({
   Name = "Low Velocity Mode (Easier Hit)",
   CurrentValue = false,
   Callback = function(Value)
      getrenv().var16_upvw = Value   -- getHitVelocity_upvr で2.2に固定される
      Rayfield:Notify({
         Title = "Velocity Mode",
         Content = Value and "Low velocity ON (easier)" or "Normal velocity",
         Duration = 3.5,
      })
   end,
})

-- 視覚系グループ
local VisualGroup = MainTab:CreateSection("Visuals")

VisualGroup:CreateToggle({
   Name = "Show Ball Trajectory (Simple)",
   CurrentValue = false,
   Flag = "TrajToggle",
   Callback = function(Value)
      if Value then
         -- 簡易実装例（Heartbeatで線を引く）
         task.spawn(function()
            local lastPos = workspace.CurrentCamera.CFrame.Position
            while getrenv().var13_upvw and getrenv().var13_upvw.Parent do
               local ball = getrenv().var13_upvw
               if ball then
                  local beam = Instance.new("Beam")
                  beam.Attachment0 = Instance.new("Attachment", workspace.Terrain)
                  beam.Attachment0.WorldPosition = lastPos
                  beam.Attachment1 = Instance.new("Attachment", workspace.Terrain)
                  beam.Attachment1.WorldPosition = ball.Position
                  beam.Color = ColorSequence.new(Color3.new(1,0,0))
                  beam.Width0 = 0.4
                  beam.Width1 = 0.4
                  beam.Parent = workspace
                  task.delay(8, function() beam:Destroy() end)
                  lastPos = ball.Position
               end
               task.wait(0.08)
            end
         end)
      end
   end,
})

-- 終了ボタンなど
local UtilityTab = Window:CreateTab("Utility")

UtilityTab:CreateButton({
   Name = "Unload UI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

Rayfield:Notify({
   Title = "Loaded Successfully",
   Content = "PingPong! client tools ready.\nNote: Many actions are client-side simulation only.",
   Duration = 6,
   Image = 4483362458,
})
