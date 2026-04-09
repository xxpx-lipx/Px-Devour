local players = game:GetService("Players")
local run = game:GetService("RunService")
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local lp = players.LocalPlayer

local c3 = Color3.fromRGB
local ud = UDim.new
local ud2 = UDim2.new
local f_gb = Enum.Font.GothamBold

local fileName = "Px_Devour_Pos.txt"

local function savePos(pos)
    if writefile then
        local str = string.format("%f,%d,%f,%d", pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
        writefile(fileName, str)
    end
end

local function loadPos()
    if readfile and isfile and isfile(fileName) then
        local str = readfile(fileName)
        local parts = string.split(str, ",")
        if #parts == 4 then
            return ud2(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]))
        end
    end
    return ud2(0.5, -115, 0.5, -87)
end

local function mk(cls, prnt, props)
    local i = Instance.new(cls, prnt)
    for k, v in pairs(props) do i[k] = v end
    return i
end

local devourEnabled = false
local stealDevourEnabled = false
local cloneDevourEnabled = false
local cloneDevourTriggered = false
local stealAutoTriggered = false
local devourSetter = nil

local plots = workspace:WaitForChild("Plots")

local function CleanAcc(char)
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") then v:Destroy() end
    end
end

local function MonitorPlayer(p)
    p.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid")
        CleanAcc(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Accessory") then task.defer(function() child:Destroy() end) end
        end)
    end)
    if p.Character then CleanAcc(p.Character) end
end

for _, p in pairs(players:GetPlayers()) do MonitorPlayer(p) end
players.PlayerAdded:Connect(MonitorPlayer)

task.spawn(function()
    while true do
        task.wait(0.05)
        if (devourEnabled or cloneDevourTriggered or stealAutoTriggered) and lp.Character then
            local h = lp.Character:FindFirstChildOfClass("Humanoid")
            local b = lp.Backpack:FindFirstChild("Bat") or lp.Character:FindFirstChild("Bat")
            if b and h then
                h:EquipTool(b)
                task.wait(0.05)
                h:UnequipTools()
            end
        end
    end
end)

run.RenderStepped:Connect(function()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local dir = hum.MoveDirection
    if dir.Magnitude > 0.05 then
        hrp.AssemblyLinearVelocity = Vector3.new(dir.X * 26, hrp.AssemblyLinearVelocity.Y, dir.Z * 26)
    end
end)

local function triggerDevourAuto()
    if stealDevourEnabled then
        stealAutoTriggered = true
    end
end

local function setupPromptMonitor(prompt)
    if not prompt:IsA("ProximityPrompt") or prompt.ActionText ~= "Steal" then return end
    prompt.Triggered:Connect(function()
        triggerDevourAuto()
    end)
end

for _, desc in pairs(plots:GetDescendants()) do setupPromptMonitor(desc) end
plots.DescendantAdded:Connect(setupPromptMonitor)

local function checkCloneTool(tool)
    if tool:IsA("Tool") and tool.Name:lower():find("clone") then
        tool.Activated:Connect(function()
            if cloneDevourEnabled then
                task.spawn(function()
                    task.wait(1)
                    if cloneDevourEnabled then cloneDevourTriggered = true end
                end)
            end
        end)
    end
end

local function hookPlayerTools()
    local function monitorContainer(container)
        for _, item in pairs(container:GetChildren()) do checkCloneTool(item) end
        container.ChildAdded:Connect(checkCloneTool)
    end
    if lp.Character then monitorContainer(lp.Character) end
    if lp:FindFirstChild("Backpack") then monitorContainer(lp.Backpack) end
    lp.CharacterAdded:Connect(function(char)
        monitorContainer(char)
        local bp = lp:WaitForChild("Backpack", 5)
        if bp then monitorContainer(bp) end
    end)
end
hookPlayerTools()

local function cDEVOUR()
    local g = mk("ScreenGui", game:GetService("CoreGui"), {Name = "Px_Devour_UI", IgnoreGuiInset = true})
    local f = mk("Frame", g, {BackgroundColor3 = c3(15,40,25), BackgroundTransparency = 0.2, Size = ud2(0,230,0,175), Position = loadPos(), BorderSizePixel = 0, ClipsDescendants = true})
    mk("UICorner", f, {CornerRadius = ud(0,12)})
    local mS = mk("UIStroke", f, {Thickness = 2, Color = c3(255,255,255), ApplyStrokeMode = "Border"})
    local mG = mk("UIGradient", mS, {Color = ColorSequence.new(c3(54,152,118), c3(113,255,158))})
    run.RenderStepped:Connect(function(dt) if mG.Parent then mG.Rotation = (mG.Rotation + 120 * dt) % 360 end end)

    local tb = mk("Frame", f, {Size = ud2(1,0,0,40), BackgroundColor3 = c3(20,80,60), BorderSizePixel = 0})
    mk("UIGradient", tb, {Color = mG.Color, Rotation = 45})
    mk("UICorner", tb, {CornerRadius = ud(0,12)})
    mk("TextLabel", tb, {Size = ud2(1,-40,1,0), Position = ud2(0,12,0,0), BackgroundTransparency = 1, Text = "Px Devour", TextColor3 = c3(255,255,255), Font = f_gb, TextSize = 14, TextXAlignment = "Left"})
    local tB = mk("TextButton", tb, {Size = ud2(0,24,0,24), Position = ud2(1,-32,0,8), Text = "－", BackgroundColor3 = c3(30,60,45), TextColor3 = c3(255,255,255), Font = f_gb, TextSize = 14})
    mk("UICorner", tB, {CornerRadius = ud(0,6)})

    local iF = mk("Frame", f, {Position = ud2(0,0,0,40), Size = ud2(1,0,1,-40), BackgroundTransparency = 1})

    local function cTg(name, yPos)
        local container = mk("Frame", iF, {Size = ud2(1,0,0,40), Position = ud2(0,0,0,yPos), BackgroundTransparency = 1})
        local lab = mk("TextLabel", container, {Size = ud2(0, 130, 1, 0), Position = ud2(0, 15, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = c3(255,255,255), Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = "Left"})
        
        if name == "Devour" then
            local keyLabel = mk("TextLabel", container, {Size = ud2(0, 20, 1, 0), BackgroundTransparency = 1, Text = "(G)", TextColor3 = c3(180,180,180), Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = "Left"})
            run.RenderStepped:Connect(function()
                keyLabel.Position = ud2(0, lab.Position.X.Offset + lab.TextBounds.X + 5, 0, 0)
            end)
        end
        
        local s = mk("TextButton", container, {Size = ud2(0,45,0,22), Position = ud2(1,-60,0.5,-11), BackgroundColor3 = c3(40,40,40), BackgroundTransparency = 0.3, Text = ""})
        mk("UICorner", s, {CornerRadius = ud(1,0)})
        local k = mk("Frame", s, {Size = ud2(0,18,0,18), Position = ud2(0,2,0.5,-9), BackgroundColor3 = c3(200,200,200)})
        mk("UICorner", k, {CornerRadius = ud(1,0)})

        local st = false

        local function upd()
            if name == "Steal Devour" then stealDevourEnabled = st if not st then stealAutoTriggered = false end
            elseif name == "Clone Devour" then cloneDevourEnabled = st if not st then cloneDevourTriggered = false end 
            elseif name == "Devour" then devourEnabled = st end
            ts:Create(k, TweenInfo.new(0.2), {Position = st and ud2(1,-20,0.5,-9) or ud2(0,2,0.5,-9), BackgroundColor3 = st and c3(113,255,158) or c3(200,200,200)}):Play()
            ts:Create(s, TweenInfo.new(0.2), {BackgroundColor3 = st and c3(30,100,60) or c3(40,40,40)}):Play()
        end

        s.MouseButton1Click:Connect(function() st = not st upd() end)
        if name == "Devour" then devourSetter = {set = function(v) st = v upd() end, get = function() return st end} end
    end

    cTg("Steal Devour", 5)
    cTg("Clone Devour", 45)
    cTg("Devour", 85)

    local op = true
    tB.MouseButton1Click:Connect(function() 
        op = not op 
        tB.Text = op and "－" or "＋" 
        ts:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = op and ud2(0,230,0,175) or ud2(0,230,0,40)}):Play() 
        iF.Visible = op 
    end)
    
    local dr, ds, sp;
    f.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr, ds, sp = true, i.Position, f.Position end end)
    uis.InputChanged:Connect(function(i) if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
        local dl = i.Position - ds 
        f.Position = ud2(sp.X.Scale, sp.X.Offset+dl.X, sp.Y.Scale, sp.Y.Offset+dl.Y) 
    end end)
    uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false savePos(f.Position) end end)
end

cDEVOUR()

uis.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.G and devourSetter then 
        devourSetter.set(not devourSetter.get()) 
    end
end)
