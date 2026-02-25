local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local hum = character:WaitForChild("Humanoid")

local FLING_VELOCITY = 250000 
local DETECT_RANGE = 10000
local GUN_DIST = 75
local KNIFE_DIST = 15

local function spawnSoldier()
    local accessories = {}
    
    -- Fix 1: Immediate Transparency Bypass
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            part.CanCollide = false
        end
    end

    -- Fix 2: Recursive Accessory Search (Ensures hats are found)
    for _, acc in pairs(character:GetChildren()) do
        if acc:IsA("Accessory") then
            local h = acc:FindFirstChild("Handle") or acc:FindFirstChildWhichIsA("BasePart")
            if h then 
                h:BreakJoints()
                h.CanCollide = false
                -- Fix 3: Force Network Ownership via Velocity bypass
                table.insert(accessories, h)
            end
        end
    end

    if #accessories == 0 then
        warn("SOLDIER ERROR: No Accessories detected on your avatar!")
        return
    end

    -- Fix 4: Persistent CFrame Alignment
    RunService.Heartbeat:Connect(function()
        for i, handle in ipairs(accessories) do
            handle.Velocity = Vector3.new(35, 35, 35) -- Netless Velocity
            if i == 1 then -- Head
                handle.CFrame = root.CFrame * CFrame.new(0, 2, -3)
            elseif i == 2 then -- Body
                handle.CFrame = root.CFrame * CFrame.new(0, 0, -3)
            else -- Weapon/Limbs
                handle.CFrame = root.CFrame * CFrame.new(1, -0.5, -3.5)
            end
        end
    end)
end

local function attack(target, mode)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    if mode == "Gun" then
        bv.Velocity = (target.Position - root.Position).Unit * FLING_VELOCITY
    else
        bv.Velocity = Vector3.new(0, FLING_VELOCITY, 0)
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(0, 30000, 0)
        bav.Parent = root
        task.delay(0.2, function() bav:Destroy() end)
    end
    bv.Parent = root
    task.wait(0.1)
    bv:Destroy()
end

local function startAI()
    while task.wait(0.1) do
        local target = nil
        local dist = DETECT_RANGE
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    target = p.Character.HumanoidRootPart
                end
            end
        end
        if target then
            if dist < KNIFE_DIST then
                attack(target, "Knife")
            elseif dist < GUN_DIST then
                attack(target, "Gun")
                hum:MoveTo(target.Position)
            else
                -- Fix 5: Adaptive Pathfinding
                local path = PathfindingService:CreatePath({AgentCanJump = true})
                path:ComputeAsync(root.Position, target.Position)
                if path.Status == Enum.PathStatus.Success then
                    local waypoints = path:GetWaypoints()
                    if waypoints[2] then
                        if waypoints[2].Action == Enum.PathWaypointAction.Jump then
                            hum.Jump = true
                        end
                        hum:MoveTo(waypoints[2].Position)
                    end
                end
            end
        end
    end
end

spawnSoldier()
task.spawn(startAI)
