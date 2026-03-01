-- [Made by ranzzie] -- https://rifatraditya.me/

print("[MEGA PENCARI KATA PRO] Memulai...")

-- LAYANAN =====================================================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- KONFIGURASI =================================================================
local CONFIG = {
    typingSpeed = 0.05,        -- Kecepatan mengetik (detik antar huruf)
    minLength = 3,             -- Panjang kata minimum
    maxLength = 17,            -- Panjang kata maksimum
    idealLength = 6,           -- Panjang ideal untuk prioritas
    autoResetTime = 300,       -- 5 menit dalam detik
    wordsPerPage = 10,         -- Kata per halaman
}

-- WARNA TEMA ==================================================================
local THEME = {
    bg          = Color3.fromRGB(12, 12, 18),
    bgCard      = Color3.fromRGB(18, 18, 28),
    accent      = Color3.fromRGB(0, 200, 255),
    accentDim   = Color3.fromRGB(0, 120, 180),
    green       = Color3.fromRGB(0, 255, 130),
    red         = Color3.fromRGB(255, 60, 80),
    yellow      = Color3.fromRGB(255, 220, 50),
    purple      = Color3.fromRGB(180, 60, 255),
    nuke        = Color3.fromRGB(255, 80, 20),
    nukeDim     = Color3.fromRGB(180, 40, 10),
    textPrimary = Color3.fromRGB(230, 240, 255),
    textDim     = Color3.fromRGB(120, 130, 150),
    glow        = Color3.fromRGB(0, 255, 255),
}

-- Kata-kata umum yang diabaikan
local commonWords = {
    ["dan"] = true, ["di"] = true, ["ke"] = true, ["dari"] = true,
    ["yang"] = true, ["ini"] = true, ["itu"] = true, ["ada"] = true,
    ["untuk"] = true, ["dengan"] = true, ["pada"] = true, ["juga"] = true,
    ["atau"] = true, ["akan"] = true, ["oleh"] = true, ["tapi"] = true,
    ["sudah"] = true, ["saya"] = true, ["kami"] = true, ["kita"] = true,
    ["dia"] = true, ["mereka"] = true, ["bisa"] = true, ["harus"] = true,
    ["lagi"] = true, ["saja"] = true, ["jadi"] = true, ["kalau"] = true,
    ["ya"] = true, ["tak"] = true, ["apa"] = true, ["pun"] = true,
}

-- URL Kamus
local DICTIONARY_URLS = {
    "https://raw.githubusercontent.com/perlancar/perl-WordList-ID-KBBI/master/lib/WordList/ID/KBBI.pm",
}

-- Daftar cadangan lokal
local FALLBACK_WORDS = {
    "gajah", "harimau", "elang", "singa", "merpati", "kupu",
    "hutan", "pantai", "gunung", "sungai", "pelangi", "awan",
    "petir", "bahari", "samudra", "tanjung", "telaga", "bunga",
    "mentari", "rembulan", "cahaya", "bayangan", "temaram", "binar",
    "semburat", "embun", "desa", "kota", "pasar", "perahu",
}

local MIN_LOAD_COUNT = 500

-- VARIABEL GLOBAL =============================================================
local allWords = {}
local wordSet = {}
local consoleAutoComplete = false
local collectedLetters = {}
local usedWords = {}
local lastWordTime = 0
local topWords = {}
local selectedIndex = 1
local currentPage = 1


-- UTILITAS ====================================================================
local function tweenProp(obj, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.accent
    s.Thickness = thickness or 1.5
    s.Transparency = 0.3
    s.Parent = parent
    return s
end

local function makePadding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 6)
    p.PaddingBottom = UDim.new(0, b or 6)
    p.PaddingLeft = UDim.new(0, l or 10)
    p.PaddingRight = UDim.new(0, r or 10)
    p.Parent = parent
    return p
end

local function makeGradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = parent
    return g
end

-- PENGATURAN GUI ==============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MegaWordSearchPro"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Panel utama (container) =====================================================
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 420, 0, 560)
mainPanel.Position = UDim2.new(1, -440, 1, -580)
mainPanel.BackgroundColor3 = THEME.bg
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui
makeCorner(mainPanel, 14)
makeStroke(mainPanel, THEME.accent, 2)
makeGradient(mainPanel, THEME.bg, THEME.bgCard, 180)

-- Panel bisa di-drag
local dragging, dragStart, startPos
mainPanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainPanel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
mainPanel.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Header ======================================================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = THEME.bgCard
header.BorderSizePixel = 0
header.Parent = mainPanel
makeCorner(header, 14)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -20, 1, 0)
headerLabel.Position = UDim2.new(0, 10, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Font = Enum.Font.GothamBlack
headerLabel.TextSize = 16
headerLabel.TextColor3 = THEME.accent
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Text = "KBBI SCRIPT"
headerLabel.Parent = header

local wordCountLabel = Instance.new("TextLabel")
wordCountLabel.Size = UDim2.new(0, 120, 1, 0)
wordCountLabel.Position = UDim2.new(1, -130, 0, 0)
wordCountLabel.BackgroundTransparency = 1
wordCountLabel.Font = Enum.Font.GothamBold
wordCountLabel.TextSize = 11
wordCountLabel.TextColor3 = THEME.textDim
wordCountLabel.TextXAlignment = Enum.TextXAlignment.Right
wordCountLabel.Text = "⏳ Memuat..."
wordCountLabel.Parent = header

-- Kotak Pencarian =============================================================
local searchFrame = Instance.new("Frame")
searchFrame.Name = "SearchFrame"
searchFrame.Size = UDim2.new(1, -20, 0, 44)
searchFrame.Position = UDim2.new(0, 10, 0, 52)
searchFrame.BackgroundColor3 = THEME.bgCard
searchFrame.BorderSizePixel = 0
searchFrame.Parent = mainPanel
makeCorner(searchFrame, 10)
makeStroke(searchFrame, THEME.accentDim, 1.5)

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -16, 1, 0)
searchBox.Position = UDim2.new(0, 8, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextColor3 = THEME.textPrimary
searchBox.PlaceholderText = "🔎 Ketik huruf awal..."
searchBox.PlaceholderColor3 = THEME.textDim
searchBox.Font = Enum.Font.GothamBold
searchBox.TextSize = 22
searchBox.ClearTextOnFocus = false
searchBox.TextEditable = true
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchFrame

-- Baris Tombol ================================================================
local btnRow = Instance.new("Frame")
btnRow.Name = "ButtonRow"
btnRow.Size = UDim2.new(1, -20, 0, 36)
btnRow.Position = UDim2.new(0, 10, 0, 104)
btnRow.BackgroundTransparency = 1
btnRow.Parent = mainPanel

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
btnLayout.Padding = UDim.new(0, 6)
btnLayout.Parent = btnRow

local function makeButton(name, text, color, width)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, width or 90, 1, 0)
    btn.BackgroundColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = THEME.textPrimary
    btn.Text = text
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = btnRow
    makeCorner(btn, 8)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        tweenProp(btn, {BackgroundColor3 = Color3.new(
            math.min(color.R * 1.3, 1),
            math.min(color.G * 1.3, 1),
            math.min(color.B * 1.3, 1)
        )}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tweenProp(btn, {BackgroundColor3 = color}, 0.2)
    end)
    return btn
end

local toggleButton = makeButton("Toggle", "🔴 Konsol", THEME.red, 90)
local trollButton = makeButton("Troll", "😈 Troll", THEME.purple, 78)
local nukeButton = makeButton("Nuke", "☢ NUKE", THEME.nuke, 78)
local resetButton = makeButton("Reset", "🔄 Reset", Color3.fromRGB(50, 55, 65), 78)

-- Speed Slider ================================================================
local speedRow = Instance.new("Frame")
speedRow.Name = "SpeedRow"
speedRow.Size = UDim2.new(1, -20, 0, 28)
speedRow.Position = UDim2.new(0, 10, 0, 144)
speedRow.BackgroundTransparency = 1
speedRow.Parent = mainPanel

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 80, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 11
speedLabel.TextColor3 = THEME.textDim
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "Speed: " .. tostring(CONFIG.typingSpeed * 1000) .. "ms"
speedLabel.Parent = speedRow

local sliderBg = Instance.new("Frame")
sliderBg.Name = "SliderBg"
sliderBg.Size = UDim2.new(1, -130, 0, 8)
sliderBg.Position = UDim2.new(0, 85, 0.5, -4)
sliderBg.BackgroundColor3 = THEME.bgCard
sliderBg.BorderSizePixel = 0
sliderBg.Parent = speedRow
makeCorner(sliderBg, 4)
makeStroke(sliderBg, THEME.accentDim, 1)

local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.BackgroundColor3 = THEME.accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
makeCorner(sliderFill, 4)

local sliderKnob = Instance.new("Frame")
sliderKnob.Name = "Knob"
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.BackgroundColor3 = THEME.textPrimary
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBg
makeCorner(sliderKnob, 7)

-- Slider: min 0.01s, max 0.25s
local SPEED_MIN, SPEED_MAX = 0.01, 0.25
local function speedToFraction(s)
    return math.clamp((s - SPEED_MIN) / (SPEED_MAX - SPEED_MIN), 0, 1)
end
local function fractionToSpeed(f)
    return SPEED_MIN + f * (SPEED_MAX - SPEED_MIN)
end

local function updateSliderVisual(fraction)
    sliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    sliderKnob.Position = UDim2.new(fraction, 0, 0.5, 0)
    local ms = math.floor(fractionToSpeed(fraction) * 1000 + 0.5)
    speedLabel.Text = "Speed: " .. ms .. "ms"
end

-- Inisialisasi posisi slider
updateSliderVisual(speedToFraction(CONFIG.typingSpeed))

local sliderDragging = false
sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)
sliderBg.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local absPos = sliderBg.AbsolutePosition.X
        local absSize = sliderBg.AbsoluteSize.X
        local fraction = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
        CONFIG.typingSpeed = fractionToSpeed(fraction)
        updateSliderVisual(fraction)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

-- Tombol preset kecepatan
local speedBtnFrame = Instance.new("Frame")
speedBtnFrame.Size = UDim2.new(0, 40, 1, 0)
speedBtnFrame.Position = UDim2.new(1, -40, 0, 0)
speedBtnFrame.BackgroundTransparency = 1
speedBtnFrame.Parent = speedRow

local speedBtnLayout = Instance.new("UIListLayout")
speedBtnLayout.FillDirection = Enum.FillDirection.Horizontal
speedBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
speedBtnLayout.Padding = UDim.new(0, 3)
speedBtnLayout.Parent = speedBtnFrame

local function makeSpeedPreset(label, value)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 18, 0, 18)
    b.Position = UDim2.new(0, 0, 0.5, -9)
    b.BackgroundColor3 = THEME.bgCard
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = THEME.accent
    b.Text = label
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = speedBtnFrame
    makeCorner(b, 4)
    b.MouseButton1Click:Connect(function()
        CONFIG.typingSpeed = value
        updateSliderVisual(speedToFraction(value))
    end)
    return b
end

makeSpeedPreset("F", 0.02)  -- Fast
makeSpeedPreset("S", 0.12)  -- Slow

-- Status Bar ==================================================================
local statusBar = Instance.new("TextLabel")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -20, 0, 18)
statusBar.Position = UDim2.new(0, 10, 0, 176)
statusBar.BackgroundTransparency = 1
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 11
statusBar.TextColor3 = THEME.textDim
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.Text = ""
statusBar.Parent = mainPanel

-- Frame Hasil =================================================================
local resultsFrame = Instance.new("Frame")
resultsFrame.Name = "Results"
resultsFrame.Size = UDim2.new(1, -20, 0, 320)
resultsFrame.Position = UDim2.new(0, 10, 0, 200)
resultsFrame.BackgroundColor3 = THEME.bgCard
resultsFrame.BackgroundTransparency = 0.4
resultsFrame.BorderSizePixel = 0
resultsFrame.ClipsDescendants = true
resultsFrame.Parent = mainPanel
makeCorner(resultsFrame, 10)

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.Padding = UDim.new(0, 3)
resultsLayout.Parent = resultsFrame
makePadding(resultsFrame, 6, 6, 8, 8)

-- Kotak Seleksi
local selectionBox = Instance.new("Frame")
selectionBox.BackgroundTransparency = 0.6
selectionBox.BackgroundColor3 = THEME.green
selectionBox.BorderSizePixel = 0
selectionBox.Visible = false
selectionBox.ZIndex = 0
selectionBox.Parent = resultsFrame
makeCorner(selectionBox, 6)

-- Panah Halaman ===============================================================
local pageFrame = Instance.new("Frame")
pageFrame.Name = "PageFrame"
pageFrame.Size = UDim2.new(1, -20, 0, 28)
pageFrame.Position = UDim2.new(0, 10, 1, -34)
pageFrame.BackgroundTransparency = 1
pageFrame.Parent = mainPanel

local pageLabel = Instance.new("TextLabel")
pageLabel.Size = UDim2.new(1, 0, 1, 0)
pageLabel.BackgroundTransparency = 1
pageLabel.Font = Enum.Font.GothamBold
pageLabel.TextSize = 12
pageLabel.TextColor3 = THEME.textDim
pageLabel.Text = ""
pageLabel.Parent = pageFrame

local function makeArrow(text, posX)
    local a = Instance.new("TextButton")
    a.Size = UDim2.new(0, 30, 0, 28)
    a.Position = UDim2.new(posX, posX > 0.5 and -30 or 0, 0, 0)
    a.BackgroundColor3 = THEME.bgCard
    a.Font = Enum.Font.GothamBlack
    a.TextSize = 16
    a.TextColor3 = THEME.accent
    a.Text = text
    a.AutoButtonColor = false
    a.BorderSizePixel = 0
    a.Parent = pageFrame
    makeCorner(a, 6)
    return a
end

local leftArrow = makeArrow("◀", 0)
local rightArrow = makeArrow("▶", 1)

-- SISTEM NOTIFIKASI ===========================================================
local function notify(message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Mega Pencari Kata Pro",
            Text = message,
            Duration = 3
        })
    end)
end

local function setStatus(msg, color)
    statusBar.Text = msg
    statusBar.TextColor3 = color or THEME.textDim
end

-- PENDENGAR KONSOL ============================================================
-- Pola-pola yang dikenali (case-insensitive):
--   "Word: AB"  /  "Hurufnya adalah: AB"  /  "Huruf: AB"  /  "Letters: AB"
--   atau pesan pendek hanya berisi 2-6 huruf kapital
local LETTER_PATTERNS = {
    "Word[%s:]+([%a]+)",
    "[Hh]uruf[%a]*[%s:]+[%a]*[%s:]*([%a]+)",
    "[Ll]etters?[%s:]+([%a]+)",
    "[Hh]int[%s:]+([%a]+)",
    "adalah[%s:]+([%a]+)",
}

local function extractLetters(message)
    -- Coba setiap pola
    for _, pat in ipairs(LETTER_PATTERNS) do
        local raw = message:match(pat)
        if raw then
            local letters = raw:upper()
            if #letters >= 1 and #letters <= 6 then
                return letters
            end
        end
    end

    -- Fallback: jika pesan hanya berisi 1-6 huruf kapital (tanpa teks lain)
    local stripped = message:gsub("%s+", "")
    if stripped:match("^%u%u?%u?%u?%u?%u?$") and #stripped >= 1 and #stripped <= 6 then
        return stripped
    end

    return nil
end

local function handleDetectedLetters(letters, source)
    if not consoleAutoComplete then return end
    if not letters or letters == "" then return end

    lastWordTime = tick()
    table.insert(collectedLetters, letters)
    print("[" .. source .. "] Huruf terdeteksi: " .. letters)
    setStatus("📝 Huruf terdeteksi: " .. letters .. " (" .. source .. ")", THEME.green)
    notify("📝 " .. letters .. " terdeteksi!")
    searchBox.Text = letters
end

local function handleConsoleMessage(message)
    if not consoleAutoComplete then return end

    -- Hindari mendeteksi output sendiri
    if message:find("%[KONSOL%]") or message:find("%[MEGA") or message:find("%[RESET")
       or message:find("%[GUI%-SCAN%]") or message:find("%[SISTEM%]") then
        return
    end

    local letters = extractLetters(message)
    if not letters then return end

    handleDetectedLetters(letters, "KONSOL")
end

-- Dengarkan semua output log
LogService.MessageOut:Connect(function(message, messageType)
    handleConsoleMessage(message)
end)

-- Juga dengarkan ScriptContext error (beberapa game log via warn/error)
pcall(function()
    LogService.ServerMessageOut:Connect(function(message, messageType)
        handleConsoleMessage(message)
    end)
end)

-- PEMINDAI GUI (GUI SCANNER) ==================================================
-- Memindai UI game untuk menemukan teks "Hurufnya adalah:" dan huruf di dalamnya
-- Ini menangkap huruf yang ditampilkan sebagai elemen visual, bukan log konsol

local lastDetectedGuiLetter = ""
local lastDetectedGuiTime = 0

local function extractLetterFromText(text)
    if not text or text == "" then return nil end

    -- Pola: "Hurufnya adalah: A" atau "Hurufnya adalah:A"
    local letter = text:match("[Hh]uruf[%a]*%s+adalah[%s:]*(%a+)")
    if letter and #letter >= 1 and #letter <= 6 then
        return letter:upper()
    end

    -- Pola: "Word: A" / "Hint: AB" dll
    for _, pat in ipairs(LETTER_PATTERNS) do
        local raw = text:match(pat)
        if raw and #raw >= 1 and #raw <= 6 then
            return raw:upper()
        end
    end

    return nil
end

local function scanGuiForLetters()
    -- Scan semua GUI di PlayerGui (kecuali GUI kita sendiri)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "MegaWordSearchPro" then
            -- Cari semua TextLabel/TextButton di dalam GUI ini
            for _, desc in ipairs(gui:GetDescendants()) do
                pcall(function()
                    if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible then
                        local text = desc.Text

                        -- Cek apakah teks mengandung pola huruf
                        local letter = extractLetterFromText(text)
                        if letter then
                            -- Jika ini huruf baru yang belum dideteksi
                            if letter ~= lastDetectedGuiLetter or (tick() - lastDetectedGuiTime) > 3 then
                                lastDetectedGuiLetter = letter
                                lastDetectedGuiTime = tick()
                                handleDetectedLetters(letter, "GUI-SCAN")
                            end
                            return
                        end

                        -- Cek apakah ada "Hurufnya adalah" di TextLabel ini,
                        -- dan hurufnya di TextLabel sibling/child terdekat
                        if text:lower():find("huruf") and text:lower():find("adalah") then
                            local parent = desc.Parent
                            if parent then
                                for _, sibling in ipairs(parent:GetChildren()) do
                                    if sibling ~= desc and (sibling:IsA("TextLabel") or sibling:IsA("TextButton")) then
                                        local sibText = sibling.Text:gsub("%s+", "")
                                        if #sibText >= 1 and #sibText <= 6 and sibText:match("^%a+$") then
                                            local foundLetter = sibText:upper()
                                            if foundLetter ~= lastDetectedGuiLetter or (tick() - lastDetectedGuiTime) > 3 then
                                                lastDetectedGuiLetter = foundLetter
                                                lastDetectedGuiTime = tick()
                                                handleDetectedLetters(foundLetter, "GUI-SCAN")
                                            end
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end

-- Loop pemindai GUI: scan setiap 0.5 detik saat konsol listener aktif
task.spawn(function()
    while task.wait(0.5) do
        if consoleAutoComplete then
            pcall(scanGuiForLetters)
        end
    end
end)

-- SISTEM RESET OTOMATIS =======================================================
task.spawn(function()
    while task.wait(10) do
        if lastWordTime > 0 and tick() - lastWordTime > CONFIG.autoResetTime then
            usedWords = {}
            lastWordTime = 0
            print("[RESET-OTOMATIS] Daftar kata terpakai direset (5 menit tidak aktif)")
            setStatus("🔄 Auto-reset selesai", THEME.yellow)
            notify("🔄 Reset otomatis dilakukan!")
        end
    end
end)

-- MEMUAT KAMUS ================================================================
local function sanitizeWord(raw)
    local bom = string.char(0xEF, 0xBB, 0xBF)
    local w = raw:gsub("^" .. bom, "")
    w = w:gsub("^%s+", ""):gsub("%s+$", "")
    w = w:lower()
    if w == "" then return nil end
    if not w:match("^[%a%-']+$") then return nil end
    local len = #w
    if len < CONFIG.minLength or len > CONFIG.maxLength then return nil end
    if commonWords[w] then return nil end
    return w
end

local function addWord(word)
    if not word or wordSet[word] then return false end
    table.insert(allWords, word)
    wordSet[word] = true
    return true
end

local function loadFromJSON(content)
    local success, wordsJson = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not success or type(wordsJson) ~= "table" then return 0 end

    local added = 0
    for word, _ in pairs(wordsJson) do
        local clean = sanitizeWord(tostring(word))
        if clean and addWord(clean) then
            added = added + 1
        end
    end
    return added
end

local function loadFromText(content)
    local added = 0
    for word in content:gmatch("[^\r\n]+") do
        local clean = sanitizeWord(word)
        if clean and addWord(clean) then
            added = added + 1
        end
    end
    return added
end

local function loadFromPerlModule(content)
    local _, pos = content:find("__DATA__")
    if not pos then return 0 end

    local dataSection = content:sub(pos + 7)
    local added = 0
    for line in dataSection:gmatch("[^\r\n]+") do
        if line:match("^__END__") then break end
        if not line:match("^__DATA__") and not line:match("^%s*#") then
            local clean = sanitizeWord(line)
            if clean and addWord(clean) then
                added = added + 1
            end
        end
    end
    return added
end

local function loadDictionary()
    print("[INFO] Mengunduh kamus...")
    setStatus("⏳ Mengunduh kamus...", THEME.yellow)
    notify("Memuat kamus...")

    allWords = {}
    wordSet = {}

    for i, url in ipairs(DICTIONARY_URLS) do
        local before = #allWords
        local ok, content = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and content and #content > 0 then
            local added = 0
            if content:match("^%s*{") then
                added = loadFromJSON(content)
            elseif content:find("__DATA__") then
                added = loadFromPerlModule(content)
            else
                added = loadFromText(content)
            end

            if added > 0 and #allWords >= MIN_LOAD_COUNT then
                print("[✓] " .. (#allWords - before) .. " kata ditambah dari sumber #" .. i .. " (total " .. #allWords .. ")")
                wordCountLabel.Text = tostring(#allWords) .. " kata"
                wordCountLabel.TextColor3 = THEME.green
                searchBox.PlaceholderText = "🔎 Ketik huruf awal..."
                setStatus("✅ Kamus dimuat: " .. #allWords .. " kata", THEME.green)
                notify("✅ Kamus dimuat! (" .. #allWords .. " kata)")
                return true
            else
                warn("[PERINGATAN] Sumber #" .. i .. " tidak mencukupi (" .. added .. " kata ditambah)")
            end
        else
            warn("[PERINGATAN] Sumber #" .. i .. " gagal diunduh")
        end
    end

    for _, w in ipairs(FALLBACK_WORDS) do
        addWord(w)
    end
    warn("[ERROR] Semua sumber kamus gagal, memakai fallback lokal")
    wordCountLabel.Text = tostring(#allWords) .. " kata"
    wordCountLabel.TextColor3 = THEME.yellow
    searchBox.PlaceholderText = "⚠️ Mode fallback"
    setStatus("⚠️ Fallback lokal: " .. #allWords .. " kata", THEME.yellow)
    notify("⚠️ Fallback lokal dipakai (" .. #allWords .. " kata)")
    return true
end

-- PEMBUATAN LABEL KATA ========================================================
local function createWordLabel(parent, text, index, isFirst)
    local h = isFirst and 40 or 28
    local lbl = Instance.new("TextButton")
    lbl.Name = "Word_" .. index
    lbl.Size = UDim2.new(1, 0, 0, h)
    lbl.BackgroundColor3 = THEME.bgCard
    lbl.BackgroundTransparency = 0.5
    lbl.BorderSizePixel = 0
    lbl.Font = isFirst and Enum.Font.GothamBlack or Enum.Font.GothamBold
    lbl.TextSize = isFirst and 20 or 15
    lbl.TextColor3 = isFirst and THEME.green or THEME.textPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. text
    lbl.AutoButtonColor = false
    lbl.Parent = parent
    makeCorner(lbl, 6)

    -- Nomor urut
    local numLabel = Instance.new("TextLabel")
    numLabel.Size = UDim2.new(0, 24, 1, 0)
    numLabel.Position = UDim2.new(1, -28, 0, 0)
    numLabel.BackgroundTransparency = 1
    numLabel.Font = Enum.Font.Gotham
    numLabel.TextSize = 11
    numLabel.TextColor3 = THEME.textDim
    numLabel.Text = "#" .. index
    numLabel.Parent = lbl

    -- Hover
    lbl.MouseEnter:Connect(function()
        tweenProp(lbl, {BackgroundTransparency = 0.1, BackgroundColor3 = THEME.accent}, 0.12)
        tweenProp(lbl, {TextColor3 = THEME.bg}, 0.12)
    end)
    lbl.MouseLeave:Connect(function()
        tweenProp(lbl, {BackgroundTransparency = 0.5, BackgroundColor3 = THEME.bgCard}, 0.2)
        tweenProp(lbl, {TextColor3 = isFirst and THEME.green or THEME.textPrimary}, 0.2)
    end)

    return lbl
end

-- FUNGSI KETIK OTOMATIS =======================================================
-- prefix: huruf yang sudah diketik user (tidak perlu diketik ulang)
local function typeWord(word, prefix)
    prefix = prefix or ""
    local remaining = word:sub(#prefix + 1)
    if #remaining == 0 then
        -- Kata sudah lengkap, tinggal Enter
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        return
    end

    -- Ketik huruf yang tersisa saja
    for c in remaining:upper():gmatch(".") do
        local ok, kc = pcall(function() return Enum.KeyCode[c] end)
        if ok and kc then
            VirtualInputManager:SendKeyEvent(true, kc, false, game)
            task.wait(CONFIG.typingSpeed)
            VirtualInputManager:SendKeyEvent(false, kc, false, game)
        end
    end

    -- Enter
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

local function autoTypeWord(word, currentInput)
    task.spawn(function()
        typeWord(word, currentInput)
    end)
end

-- TAMPILAN HALAMAN ============================================================
local function displayPage()
    for _, c in ipairs(resultsFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local startIdx = (currentPage - 1) * CONFIG.wordsPerPage + 1
    local endIdx = math.min(currentPage * CONFIG.wordsPerPage, #topWords)
    local totalPages = math.max(1, math.ceil(#topWords / CONFIG.wordsPerPage))

    pageLabel.Text = "Hal " .. currentPage .. "/" .. totalPages .. "  (" .. #topWords .. " hasil)"

    for i = startIdx, endIdx do
        local isFirst = (i == startIdx and currentPage == 1)
        local lbl = createWordLabel(resultsFrame, topWords[i]:upper(), i, isFirst)

        lbl.MouseButton1Click:Connect(function()
            local word = topWords[i]
            if word then
                usedWords[word] = true
                setStatus("✅ Dipilih: " .. word:upper(), THEME.green)
                notify("✅ Dipilih: " .. word)
                autoTypeWord(word, searchBox.Text)
                searchBox.Text = ""
                selectionBox.Visible = false
            end
        end)
    end

    selectionBox.Visible = false
end

-- LOGIKA PENCARIAN ============================================================
local function updateTopWords(input)
    topWords = {}
    input = input:lower()

    if input == "" then
        selectionBox.Visible = false
        for _, c in ipairs(resultsFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        pageLabel.Text = ""
        setStatus("", THEME.textDim)
        return
    end

    for _, w in ipairs(allWords) do
        if w:sub(1, #input) == input and w ~= input and not usedWords[w] then
            table.insert(topWords, w)
        end
    end

    table.sort(topWords, function(a, b)
        local distA = math.abs(#a - CONFIG.idealLength)
        local distB = math.abs(#b - CONFIG.idealLength)
        if distA == distB then
            if #a == #b then return a < b end
            return #a < #b
        end
        return distA < distB
    end)

    setStatus("🔍 " .. #topWords .. " kata ditemukan untuk '" .. input:upper() .. "'", THEME.accent)
    currentPage = 1
    displayPage()
end

-- FITUR NUKE (SELF-DESTRUCT) ==================================================
local function nukeEverything()
    -- Hapus semua data dari memori
    allWords = {}
    wordSet = {}
    topWords = {}
    usedWords = {}
    collectedLetters = {}
    consoleAutoComplete = false

    -- Hancurkan GUI sepenuhnya
    if screenGui then
        screenGui:Destroy()
    end

    -- Cari dan hapus semua ScreenGui milik script ini (jaga-jaga duplikat)
    pcall(function()
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name == "MegaWordSearchPro" then
                gui:Destroy()
            end
        end
    end)

    -- Bersihkan log output agar tidak ada jejak print
    -- (tidak bisa dihapus sepenuhnya, tapi kita overwrite dengan spam kosong)
    for _ = 1, 30 do
        print(" ")
    end

    print("[SISTEM] Semua data telah dihapus.")
end

-- EVENT TOMBOL ================================================================
toggleButton.MouseButton1Click:Connect(function()
    consoleAutoComplete = not consoleAutoComplete

    if consoleAutoComplete then
        toggleButton.Text = "🟢 Konsol"
        tweenProp(toggleButton, {BackgroundColor3 = THEME.green}, 0.2)
        setStatus("✅ Konsol listener aktif", THEME.green)
        notify("✅ Konsol diaktifkan!")
    else
        toggleButton.Text = "🔴 Konsol"
        tweenProp(toggleButton, {BackgroundColor3 = THEME.red}, 0.2)
        setStatus("❌ Konsol listener off", THEME.red)
        notify("❌ Konsol dinonaktifkan")
    end
end)

trollButton.MouseButton1Click:Connect(function()
    if searchBox.Text == "" then
        notify("⚠️ Ketik beberapa huruf dulu!")
        setStatus("⚠️ Ketik huruf untuk troll!", THEME.yellow)
        return
    end

    local input = searchBox.Text:lower()
    local longWords = {}

    for _, w in ipairs(allWords) do
        if w:sub(1, #input) == input and not usedWords[w] and #w >= 7 then
            table.insert(longWords, w)
        end
    end

    if #longWords == 0 then
        notify("😅 Tidak ada lagi kata panjang!")
        setStatus("😅 Kata panjang habis!", THEME.yellow)
        return
    end

    table.sort(longWords, function(a, b) return #a > #b end)

    local trollWord = longWords[1]
    usedWords[trollWord] = true
    setStatus("😈 TROLL: " .. trollWord:upper() .. " (" .. #trollWord .. " huruf)", THEME.purple)
    notify("😈 TROLL: " .. trollWord:upper())
    autoTypeWord(trollWord, searchBox.Text)
    searchBox.Text = ""
end)

nukeButton.MouseButton1Click:Connect(function()
    nukeEverything()
end)

resetButton.MouseButton1Click:Connect(function()
    usedWords = {}
    lastWordTime = 0
    setStatus("🔄 Daftar kata terpakai direset!", THEME.yellow)
    notify("🔄 Daftar kata terpakai direset!")
    print("[RESET] Kata terpakai dibersihkan")
end)

-- PAGINATION
leftArrow.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        displayPage()
    end
end)

rightArrow.MouseButton1Click:Connect(function()
    if currentPage < math.ceil(#topWords / CONFIG.wordsPerPage) then
        currentPage = currentPage + 1
        displayPage()
    end
end)

-- EVENT TEKS
searchBox.Focused:Connect(function()
    searchBox.Text = ""
    selectionBox.Visible = false
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateTopWords(searchBox.Text)
end)

-- CREDIT ======================================================================
local creditLabel = Instance.new("TextLabel")
creditLabel.Name = "Credit"
creditLabel.Size = UDim2.new(1, 0, 0, 20)
creditLabel.Position = UDim2.new(0, 0, 1, -20)
creditLabel.BackgroundTransparency = 1
creditLabel.Font = Enum.Font.Gotham
creditLabel.TextSize = 11
creditLabel.TextColor3 = THEME.textDim
creditLabel.Text = "made by ranzzie  ·  rifatraditya.me"
creditLabel.Parent = mainPanel

-- ANIMASI GLOW HEADER =========================================================
task.spawn(function()
    local t = 0
    while task.wait(0.03) do
        t = t + 0.03
        local pulse = (math.sin(t * 2) + 1) / 2
        local r = THEME.accentDim.R + (THEME.accent.R - THEME.accentDim.R) * pulse
        local g = THEME.accentDim.G + (THEME.accent.G - THEME.accentDim.G) * pulse
        local b = THEME.accentDim.B + (THEME.accent.B - THEME.accentDim.B) * pulse
        headerLabel.TextColor3 = Color3.new(r, g, b)
    end
end)

-- MULAI =======================================================================
task.spawn(function()
    if loadDictionary() then
        print("[MEGA PENCARI KATA PRO – SIAP]")
        notify("🚀 Siap! " .. #allWords .. " kata dimuat")
    end
end)
