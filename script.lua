local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local hum = character:WaitForChild("Humanoid")

local FLING_VELOCITY = 200000 
local DETECT_RANGE = 10000
local GUN_DIST = 70
local KNIFE_DIST = 15

local function spawnSoldier()
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
        end
    end

    local accessories = {}
    for _, acc in pairs(character:GetChildren()) do
        if acc:IsA("Accessory") then
            local h = acc:FindFirstChild("Handle")
            if h then 
                h:BreakJoints() 
                table.insert(accessories, h)
            end
        end
    end

    RunService.Stepped:Connect(function()
        if accessories[1] then
            accessories[1].CFrame = root.CFrame * CFrame.new(0, 2, -3)
            accessories[1].Velocity = Vector3.new(35, 0, 0)
        end
        if accessories[2] then
            accessories[2].CFrame = root.CFrame * CFrame.new(0, 0, -3)
            accessories[2].Velocity = Vector3.new(35, 0, 0)
        end
        if accessories[3] then
            accessories[3].CFrame = root.CFrame * CFrame.new(2, 0, -3.5) * CFrame.Angles(math.rad(-90), 0, 0)
            accessories[3].Velocity = Vector3.new(35, 0, 0)
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
        bav.AngularVelocity = Vector3.new(0, 15000, 0)
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
