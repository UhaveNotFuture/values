--==[ FLUX UI LIBRARY ]==--
local Flux = {}

--==[ СЕРВИСЫ ]==--
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--==[ ТЕМА (Skin) ]==--
local Skin = {
    Bg         = Color3.fromRGB(16, 16, 18),
    Surface    = Color3.fromRGB(24, 24, 28),
    Surface2   = Color3.fromRGB(32, 32, 38),
    Border     = Color3.fromRGB(52, 52, 60),
    Text       = Color3.fromRGB(238, 238, 242),
    TextDim    = Color3.fromRGB(150, 150, 158),
    TextMuted  = Color3.fromRGB(96, 96, 104),
    Accent     = Color3.fromRGB(140, 140, 150),
    AccentSoft = Color3.fromRGB(180, 180, 190),
    Danger     = Color3.fromRGB(220, 80, 90),
    Success    = Color3.fromRGB(90, 200, 130),
}

local Fonts = {
    Regular = Enum.Font.Gotham,
    Medium  = Enum.Font.GothamMedium,
    Semi    = Enum.Font.GothamSemibold,
    Bold    = Enum.Font.GothamBold,
}

local FA_ATLAS_ID = "rbxassetid://8025708674"

local FA = {
    home      = {x = 0,   y = 0},
    cog       = {x = 16,  y = 0},
    user      = {x = 32,  y = 0},
    eye       = {x = 48,  y = 0},
    crosshair = {x = 64,  y = 0},
    star      = {x = 80,  y = 0},
    info      = {x = 96,  y = 0},
    list      = {x = 112, y = 0},
    sword     = {x = 0,   y = 16},
    bolt      = {x = 16,  y = 16},
    heart     = {x = 32,  y = 16},
    wrench    = {x = 48,  y = 16},
    palette   = {x = 64,  y = 16},
    code      = {x = 80,  y = 16},
    globe     = {x = 96,  y = 16},
    star4     = {x = 112, y = 16},
}

local FA_ALIAS = {
    settings = "cog", config = "cog", configs = "cog",
    target   = "crosshair", aim = "crosshair", combat = "crosshair",
    visuals  = "eye", esp = "eye",
    player   = "user", players = "user",
    misc     = "star4", other = "star4", extra = "star4",
    world    = "globe", map = "globe",
}

--==[ УТИЛИТЫ ]==--

-- Создание инстанса: Instance.new + защищённая установка свойств + дети
local function make(class, props, children)
    local ok, inst = pcall(Instance.new, class)
    if not ok or not inst then
        return nil
    end
    pcall(function()
        if inst:IsA("GuiObject") then
            inst.BorderSizePixel = 0
        end
        if inst:IsA("GuiButton") then
            inst.AutoButtonColor = false
        end
        if inst:IsA("TextButton") then
            inst.Text = ""
        end
    end)
    local parent = nil
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then
                parent = v
            else
                pcall(function()
                    inst[k] = v
                end)
            end
        end
    end
    if children then
        for _, c in ipairs(children) do
            if c then
                pcall(function()
                    c.Parent = inst
                end)
            end
        end
    end
    if parent then
        pcall(function()
            inst.Parent = parent
        end)
    end
    return inst
end

local function corner(r)
    return make("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(c, t, tr)
    return make("UIStroke", {
        Color = c,
        Thickness = t or 1,
        Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function gradient(seq, rot)
    return make("UIGradient", { Color = seq, Rotation = rot or 0 })
end

-- Твин: info может быть числом (секунды) или готовым TweenInfo
local function tween(inst, info, goal)
    if not inst then
        return nil
    end
    if type(info) == "number" then
        info = TweenInfo.new(info, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    local ok, tw = pcall(function()
        return TweenService:Create(inst, info, goal)
    end)
    if ok and tw then
        tw:Play()
        return tw
    end
    return nil
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Позиция указателя в экранных координатах (с IgnoreGuiInset = true)
local function pointerPos(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(input.Position.X, input.Position.Y)
    end
    return UserInputService:GetMouseLocation()
end

-- Проверка попадания точки в GuiObject
local function inside(g, p)
    if not g or not g.Parent then
        return false
    end
    local pos, size = g.AbsolutePosition, g.AbsoluteSize
    return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Перетаскивание frame за handle (мышь + тач). gate() может запретить драг
local function drag(frame, handle, conns, gate)
    local dragging = false
    local dragStart, startPos
    conns[#conns + 1] = handle.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        if gate and not gate() then
            return
        end
        dragging = true
        dragStart = pointerPos(input)
        startPos = frame.Position
        local ch
        ch = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if ch then
                    ch:Disconnect()
                end
            end
        end)
    end)
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            local d = pointerPos(input) - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- Безопасный вызов пользовательского callback
local function safe(cb, ...)
    if type(cb) ~= "function" then
        return
    end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[Flux] ошибка в callback: " .. tostring(err))
    end
end

local function disconnectAll(list)
    for i = #list, 1, -1 do
        local c = list[i]
        pcall(function()
            c:Disconnect()
        end)
        list[i] = nil
    end
end

local function label(props)
    local p = {
        BackgroundTransparency = 1,
        Font = Fonts.Medium,
        TextSize = 14,
        TextColor3 = Skin.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }
    for k, v in pairs(props) do
        p[k] = v
    end
    return make("TextLabel", p)
end

-- Монтирование ScreenGui: gethui -> CoreGui -> PlayerGui
local function mount(gui)
    local targets = {}
    local okH, hui = pcall(function()
        return gethui()
    end)
    if okH and hui then
        targets[#targets + 1] = hui
    end
    local okC, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okC and core then
        targets[#targets + 1] = core
    end
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            targets[#targets + 1] = pg
        end
    end
    for _, t in ipairs(targets) do
        local okP = pcall(function()
            gui.Parent = t
        end)
        if okP and gui.Parent == t then
            return true
        end
    end
    return false
end

local function buildIcon(parent, icon, color, size)
    icon = icon and tostring(icon) or ""
    size = size or 18

    -- Прямая ссылка на картинку
    if icon:find("rbxassetid://", 1, true) or icon:find("rbxasset://", 1, true)
        or icon:find("http", 1, true) == 1 then
        local img = make("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = color,
            Position = UDim2.fromOffset(11, (40 - size) / 2),
            Size = UDim2.fromOffset(size, size),
            Parent = parent,
        })
        return img, function(c) tween(img, 0.12, { ImageColor3 = c }) end
    end

    -- Имя иконки → FA атлас
    local key = string.lower(icon)
    key = FA_ALIAS[key] or key
    local glyph = FA[key]

    -- Неизвестная иконка — fallback на первую букву
    if not glyph then
        local lbl = label({
            Name = "Icon",
            Text = (icon ~= "") and string.upper(string.sub(icon, 1, 1)) or "•",
            TextSize = 16,
            Font = Fonts.Medium,
            TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.fromOffset(22, 40),
            Parent = parent,
        })
        return lbl, function(c) tween(lbl, 0.12, { TextColor3 = c }) end
    end

    -- Crop 16x16 из атласа
    local img = make("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = FA_ATLAS_ID,
        ImageRectOffset = Vector2.new(glyph.x, glyph.y),
        ImageRectSize = Vector2.new(16, 16),
        ImageColor3 = color,
        Position = UDim2.fromOffset(11, (40 - size) / 2),
        Size = UDim2.fromOffset(size, size),
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
    return img, function(c) tween(img, 0.12, { ImageColor3 = c }) end
end

-- Делает так, чтобы методы api можно было вызывать и как api:Get(), и как api.Get()
local function export(api, fns)
    for name, fn in pairs(fns) do
        api[name] = function(first, ...)
            if first == api then
                return fn(...)
            end
            return fn(first, ...)
        end
    end
    return api
end

--==[ ОБЩАЯ ИНФРАСТРУКТУРА ЭЛЕМЕНТОВ ]==--

local Elements = {}
local TabMethods = setmetatable({}, { __index = Elements })
local SectionMethods = setmetatable({}, { __index = Elements })
local TabMT = { __index = TabMethods }
local SectionMT = { __index = SectionMethods }

local function newCtx(frame)
    return { frame = frame, order = 0 }
end

local function nextOrder(ctx)
    ctx.order = ctx.order + 1
    return ctx.order
end

local function beginElement(self)
    local win = self._win
    local el = { conns = {}, accentIds = {}, destroyed = false, enabled = true }
    win._groups[#win._groups + 1] = el.conns
    return win, el
end

local function regAccent(win, el, fn)
    win._accentSeq = win._accentSeq + 1
    local id = win._accentSeq
    win._accent[id] = fn
    if el then
        el.accentIds[#el.accentIds + 1] = id
    end
end

local function destroyElement(win, el, inst)
    if el.destroyed then
        return
    end
    el.destroyed = true
    if el.cleanup then
        pcall(el.cleanup)
    end
    disconnectAll(el.conns)
    for _, id in ipairs(el.accentIds) do
        win._accent[id] = nil
    end
    if inst then
        pcall(function()
            inst:Destroy()
        end)
    end
end

local function makeRow(self, name, height, transp)
    return make("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = self._win._skin.Surface2,
        BackgroundTransparency = transp or 0.05,
        LayoutOrder = nextOrder(self._ctx),
        Parent = self._ctx.frame,
    }, { corner(6) })
end

-- Оверлей "отключено": блокирует ввод и затемняет элемент
local function attachDisable(win, el, host)
    local overlay = make("Frame", {
        Name = "Disabled",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = win._skin.Bg,
        BackgroundTransparency = 0.4,
        Active = true,
        Visible = false,
        ZIndex = 30,
        Parent = host,
    }, { corner(6) })
    return function(b)
        el.enabled = (b ~= false)
        overlay.Visible = not el.enabled
    end
end

--==[ ЭЛЕМЕНТ: SECTION ]==--
function Elements:Section(title)
    local win = self._win
    local skin = win._skin
    local parentCtx = self._baseCtx or self._ctx
    local frame = make("Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parentCtx),
        Parent = parentCtx.frame,
    }, {
        make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
        make("UIPadding", { PaddingTop = UDim.new(0, 4) }),
    })
    local ctx = newCtx(frame)
    local header = make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(ctx),
        Parent = frame,
    })
    local titleLabel = label({
        Text = string.upper(tostring(title or "")),
        Font = Fonts.Bold,
        TextSize = 11,
        TextColor3 = skin.TextMuted,
        Position = UDim2.fromOffset(2, 0),
        Size = UDim2.new(1, -4, 0, 16),
        Parent = header,
    })
    make("Frame", {
        Name = "Line",
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = skin.Border,
        BackgroundTransparency = 0.5,
        Parent = header,
    })
    local sec = setmetatable({
        _win = win,
        _ctx = ctx,
        Frame = frame,
    }, SectionMT)
    function sec:SetTitle(t)
        titleLabel.Text = string.upper(tostring(t))
    end
    function sec:Destroy()
        pcall(function()
            frame:Destroy()
        end)
    end
    -- Если секция создана на вкладке — все следующие элементы попадают в неё
    if self._isTab then
        self._ctx = ctx
    end
    return sec
end

--==[ ЭЛЕМЕНТ: TOGGLE ]==--
function Elements:Toggle(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local state = (opts.Default == true)
    local callback = opts.Callback

    local row = makeRow(self, "Toggle", 44)
    local title = label({
        Text = tostring(opts.Title or "Toggle"),
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Parent = row,
    })
    local track = make("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = skin.Surface,
        Parent = row,
    }, { corner(11), stroke(skin.Border, 1, 0.4) })
    local trackScale = make("UIScale", { Parent = track })
    local thumb = make("Frame", {
        Name = "Thumb",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = skin.TextDim,
        Parent = track,
    }, { corner(9) })
    local btn = make("TextButton", {
        Name = "Hit",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = row,
    })
    local setEnabled = attachDisable(win, el, row)

    local function render(t)
        t = t or 0.18
        tween(track, t, { BackgroundColor3 = state and skin.Accent or skin.Surface })
        tween(thumb, t, {
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = state and skin.Text or skin.TextDim,
        })
    end
    render(0)
    regAccent(win, el, function(t)
        render(t)
    end)

    local function pulse()
        tween(trackScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.08 })
        task.delay(0.10, function()
            if not el.destroyed then
                tween(trackScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
            end
        end)
    end

    el.conns[#el.conns + 1] = btn.MouseEnter:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0 })
    end)
    el.conns[#el.conns + 1] = btn.MouseLeave:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0.05 })
    end)
    el.conns[#el.conns + 1] = btn.MouseButton1Click:Connect(function()
        if not el.enabled then
            return
        end
        state = not state
        render()
        pulse()
        safe(callback, state)
    end)

    local api = {}
    return export(api, {
        Get = function()
            return state
        end,
        Set = function(v)
            state = (v == true)
            render()
        end,
        SetTitle = function(t)
            title.Text = tostring(t)
        end,
        SetEnabled = function(b)
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: SLIDER ]==--
function Elements:Slider(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local callback = opts.Callback
    local min = tonumber(opts.Min) or 0
    local max = tonumber(opts.Max) or 100
    if max <= min then
        max = min + 1
    end
    local rounding = math.max(0, math.floor(tonumber(opts.Rounding) or 0))
    local mult = 10 ^ rounding
    local fmt = "%." .. tostring(rounding) .. "f"

    local function snap(v)
        v = math.clamp(tonumber(v) or min, min, max)
        return math.floor(v * mult + 0.5) / mult
    end
    local value = snap(opts.Default or min)

    local row = makeRow(self, "Slider", 56)
    local title = label({
        Text = tostring(opts.Title or "Slider"),
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -90, 0, 22),
        Parent = row,
    })
    local pill = make("Frame", {
        Name = "Pill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 8),
        Size = UDim2.fromOffset(56, 22),
        BackgroundColor3 = skin.Accent,
        BackgroundTransparency = 0.7,
        Parent = row,
    }, { corner(4) })
    local pillText = label({
        Text = string.format(fmt, value),
        Font = Fonts.Bold,
        TextSize = 12,
        TextColor3 = skin.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        Parent = pill,
    })
    local track = make("Frame", {
        Name = "Track",
        Position = UDim2.new(0, 14, 1, -18),
        Size = UDim2.new(1, -28, 0, 6),
        BackgroundColor3 = skin.Surface,
        Parent = row,
    }, { corner(3) })
    local fillGradient = gradient(ColorSequence.new(skin.Accent, skin.AccentSoft), 0)
    local fill = make("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = track,
    }, { corner(3), fillGradient })
    local thumbStroke = stroke(skin.AccentSoft, 2, 0)
    local thumb = make("Frame", {
        Name = "Thumb",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = skin.Accent,
        ZIndex = 3,
        Parent = track,
    }, { corner(8), thumbStroke })
    local thumbScale = make("UIScale", { Parent = thumb })
    local hit = make("TextButton", {
        Name = "Hit",
        Position = UDim2.new(0, 14, 1, -27),
        Size = UDim2.new(1, -28, 0, 24),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = row,
    })
    local setEnabled = attachDisable(win, el, row)

    local function frac()
        return (value - min) / (max - min)
    end
    local function visual(t)
        local f = frac()
        tween(fill, t or 0.06, { Size = UDim2.new(f, 0, 1, 0) })
        tween(thumb, t or 0.06, { Position = UDim2.new(f, 0, 0.5, 0) })
        pillText.Text = string.format(fmt, value)
    end
    visual(0)

    regAccent(win, el, function(t)
        fillGradient.Color = ColorSequence.new(skin.Accent, skin.AccentSoft)
        tween(pill, t, { BackgroundColor3 = skin.Accent })
        tween(thumb, t, { BackgroundColor3 = skin.Accent })
        tween(thumbStroke, t, { Color = skin.AccentSoft })
    end)

    local dragging = false
    local hover = false
    local function refreshThumb()
        tween(thumbScale, 0.10, { Scale = (hover or dragging) and 1.2 or 1 })
    end

    local function updateFromX(x)
        local w = track.AbsoluteSize.X
        if w <= 0 then
            return
        end
        local f = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
        local nv = snap(min + f * (max - min))
        if nv ~= value then
            value = nv
            visual()
            safe(callback, value)
        end
    end

    el.conns[#el.conns + 1] = hit.InputBegan:Connect(function(input)
        if not el.enabled or not isPress(input) then
            return
        end
        dragging = true
        refreshThumb()
        updateFromX(pointerPos(input).X)
    end)
    el.conns[#el.conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and el.enabled and isMove(input) then
            updateFromX(pointerPos(input).X)
        end
    end)
    el.conns[#el.conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            refreshThumb()
        end
    end)
    el.conns[#el.conns + 1] = hit.MouseEnter:Connect(function()
        hover = true
        refreshThumb()
        tween(row, 0.12, { BackgroundTransparency = 0 })
    end)
    el.conns[#el.conns + 1] = hit.MouseLeave:Connect(function()
        hover = false
        refreshThumb()
        tween(row, 0.12, { BackgroundTransparency = 0.05 })
    end)

    local api = {}
    return export(api, {
        Get = function()
            return value
        end,
        Set = function(v)
            value = snap(v)
            visual()
        end,
        SetTitle = function(t)
            title.Text = tostring(t)
        end,
        SetEnabled = function(b)
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: BUTTON ]==--
function Elements:Button(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local callback = opts.Callback
    local variant = string.lower(tostring(opts.Variant or "default"))
    local titleText = tostring(opts.Title or "Button")
    local hover = false

    local st = stroke(skin.Border, 1, 0)
    local btn = make("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 0, 42),
        Text = titleText,
        Font = Fonts.Medium,
        TextSize = 14,
        TextColor3 = skin.Text,
        BackgroundColor3 = skin.Surface2,
        BackgroundTransparency = 0.05,
        LayoutOrder = nextOrder(self._ctx),
        Parent = self._ctx.frame,
    }, { corner(6), st })
    local scale = make("UIScale", { Parent = btn })
    local setEnabled = attachDisable(win, el, btn)

    local function goalFor(h)
        if variant == "accent" then
            return { BackgroundColor3 = skin.Accent, BackgroundTransparency = h and 0.6 or 0.75 },
                { Color = skin.Accent, Transparency = 0 },
                skin.Text
        elseif variant == "danger" then
            return { BackgroundColor3 = skin.Danger, BackgroundTransparency = h and 0.05 or 0.15 },
                { Color = skin.Danger, Transparency = h and 0.2 or 0.4 },
                Color3.fromRGB(255, 220, 225)
        end
        if h then
            return { BackgroundColor3 = skin.Accent, BackgroundTransparency = 0.86 },
                { Color = skin.Accent, Transparency = 0 },
                skin.Text
        end
        return { BackgroundColor3 = skin.Surface2, BackgroundTransparency = 0.05 },
            { Color = skin.Border, Transparency = 0 },
            skin.Text
    end

    local function applyStyle(h, t)
        local bg, sg, txt = goalFor(h)
        bg.TextColor3 = txt
        tween(btn, t, bg)
        tween(st, t, sg)
    end
    applyStyle(false, 0)
    regAccent(win, el, function(t)
        applyStyle(hover, t)
    end)

    el.conns[#el.conns + 1] = btn.MouseEnter:Connect(function()
        hover = true
        applyStyle(true, 0.12)
    end)
    el.conns[#el.conns + 1] = btn.MouseLeave:Connect(function()
        hover = false
        applyStyle(false, 0.12)
        tween(scale, 0.08, { Scale = 1 })
    end)
    el.conns[#el.conns + 1] = btn.MouseButton1Down:Connect(function()
        if el.enabled then
            tween(scale, 0.08, { Scale = 0.96 })
        end
    end)
    el.conns[#el.conns + 1] = btn.MouseButton1Up:Connect(function()
        tween(scale, 0.08, { Scale = 1 })
    end)
    el.conns[#el.conns + 1] = btn.MouseButton1Click:Connect(function()
        if el.enabled then
            safe(callback)
        end
    end)

    local function setTitle(t)
        titleText = tostring(t)
        btn.Text = titleText
    end
    local api = {}
    return export(api, {
        Get = function()
            return titleText
        end,
        Set = function(t)
            setTitle(t)
        end,
        SetTitle = function(t)
            setTitle(t)
        end,
        SetEnabled = function(b)
            setEnabled(b)
        end,
        Fire = function()
            if el.enabled then
                safe(callback)
            end
        end,
        Destroy = function()
            destroyElement(win, el, btn)
        end,
    })
end

--==[ ЭЛЕМЕНТ: DROPDOWN ]==--
function Elements:Dropdown(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local callback = opts.Callback

    local values = {}
    for _, v in ipairs(opts.Values or {}) do
        values[#values + 1] = v
    end
    local value = opts.Default

    local row = makeRow(self, "Dropdown", 44)
    local title = label({
        Text = tostring(opts.Title or "Dropdown"),
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -170, 1, 0),
        Parent = row,
    })
    local chip = make("TextButton", {
        Name = "Chip",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(140, 28),
        BackgroundColor3 = skin.Surface2,
        ZIndex = 5,
        Parent = row,
    }, { corner(4), stroke(skin.Border, 1, 0) })
    local valueLabel = label({
        Font = Fonts.Medium,
        TextSize = 12,
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Parent = chip,
    })
    local arrow = label({
        Text = "▾",
        TextSize = 12,
        TextColor3 = skin.TextDim,
        TextXAlignment = Enum.TextXAlignment.Center,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(14, 20),
        Parent = chip,
    })
    local setEnabled = attachDisable(win, el, row)

    local function updateChip()
        valueLabel.Text = (value ~= nil) and tostring(value) or "Select"
    end
    updateChip()

    local popup, popupScale
    local function closePopup()
        if not popup then
            return
        end
        local p, s = popup, popupScale
        popup, popupScale = nil, nil
        tween(s, 0.1, { Scale = 0.95 })
        task.delay(0.08, function()
            pcall(function()
                p:Destroy()
            end)
        end)
        tween(arrow, 0.12, { Rotation = 0 })
        if win._closePopup == closePopup then
            win._closePopup = nil
        end
    end

    local function openPopup()
        if popup or not el.enabled then
            return
        end
        if win._closePopup then
            pcall(win._closePopup)
        end
        local itemH, gap, pad = 26, 2, 4
        local count = #values
        local contentH = count * (itemH + gap) - ((count > 0) and gap or 0) + pad * 2
        local h = math.min(190, math.max(contentH, 34))
        local cpos, csize = chip.AbsolutePosition, chip.AbsoluteSize
        local screen = win._gui.AbsoluteSize
        local x = cpos.X
        local y = cpos.Y + csize.Y + 4
        if y + h > screen.Y - 4 then
            y = cpos.Y - h - 4
        end
        y = math.max(4, y)

        popup = make("Frame", {
            Name = "DropdownPopup",
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(csize.X, h),
            BackgroundColor3 = skin.Surface,
            ZIndex = 100,
            Parent = win._gui,
        }, { corner(6), stroke(skin.Border, 1, 0.2) })
        popupScale = make("UIScale", { Scale = 0.95, Parent = popup })
        tween(popupScale, 0.12, { Scale = 1 })
        tween(arrow, 0.12, { Rotation = 180 })

        local list = make("ScrollingFrame", {
            Name = "List",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = skin.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = popup,
        }, {
            make("UIPadding", {
                PaddingTop = UDim.new(0, pad), PaddingBottom = UDim.new(0, pad),
                PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad),
            }),
            make("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        for i, v in ipairs(values) do
            local active = (v == value)
            local item = make("TextButton", {
                Name = "Item",
                Size = UDim2.new(1, 0, 0, itemH),
                BackgroundColor3 = skin.Surface2,
                BackgroundTransparency = 1,
                Text = tostring(v),
                Font = active and Fonts.Bold or Fonts.Medium,
                TextSize = 12,
                TextColor3 = active and skin.Text or skin.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                LayoutOrder = i,
                Parent = list,
            }, {
                corner(4),
                make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 6) }),
            })
            if active then
                make("Frame", {
                    Name = "Bar",
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, -9, 0.5, 0),
                    Size = UDim2.fromOffset(2, 14),
                    BackgroundColor3 = skin.Accent,
                    Parent = item,
                }, { corner(1) })
            end
            item.MouseEnter:Connect(function()
                tween(item, 0.12, { BackgroundTransparency = 0.6 })
            end)
            item.MouseLeave:Connect(function()
                tween(item, 0.12, { BackgroundTransparency = 1 })
            end)
            item.MouseButton1Click:Connect(function()
                value = v
                updateChip()
                closePopup()
                safe(callback, v)
            end)
        end
        win._closePopup = closePopup
    end

    el.cleanup = closePopup
    el.conns[#el.conns + 1] = chip.MouseButton1Click:Connect(function()
        if popup then
            closePopup()
        else
            openPopup()
        end
    end)
    el.conns[#el.conns + 1] = UserInputService.InputBegan:Connect(function(input)
        if popup and isPress(input) then
            local p = pointerPos(input)
            if not inside(popup, p) and not inside(chip, p) then
                closePopup()
            end
        end
    end)
    el.conns[#el.conns + 1] = chip.MouseEnter:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0 })
    end)
    el.conns[#el.conns + 1] = chip.MouseLeave:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0.05 })
    end)

    local api = {}
    return export(api, {
        Get = function()
            return value
        end,
        Set = function(v)
            value = v
            updateChip()
        end,
        SetValues = function(list)
            closePopup()
            values = {}
            for _, v in ipairs(list or {}) do
                values[#values + 1] = v
            end
            local found = false
            for _, v in ipairs(values) do
                if v == value then
                    found = true
                    break
                end
            end
            if not found then
                value = values[1]
            end
            updateChip()
        end,
        SetTitle = function(t)
            title.Text = tostring(t)
        end,
        SetEnabled = function(b)
            if b == false then
                closePopup()
            end
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: KEYBIND ]==--
function Elements:Keybind(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local callback = opts.Callback

    local function normMode(m)
        m = string.lower(tostring(m or "Press"))
        if m == "toggle" then
            return "Toggle"
        elseif m == "hold" then
            return "Hold"
        end
        return "Press"
    end
    local mode = normMode(opts.Mode)
    local key = opts.Default
    if typeof(key) ~= "EnumItem" then
        key = nil
    end
    local listening = false
    local toggled = false
    local holding = false

    local row = makeRow(self, "Keybind", 44)
    local title = label({
        Text = tostring(opts.Title or "Keybind"),
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Parent = row,
    })
    local chipStroke = stroke(skin.Border, 1, 0)
    local chip = make("TextButton", {
        Name = "Chip",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(100, 28),
        BackgroundColor3 = skin.Surface2,
        ZIndex = 5,
        Parent = row,
    }, { corner(4), chipStroke })
    local chipText = label({
        Font = Fonts.Medium,
        TextSize = 12,
        TextColor3 = skin.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        Parent = chip,
    })
    local setEnabled = attachDisable(win, el, row)

    local function render(t)
        t = t or 0.12
        if listening then
            chipText.Text = "..."
            tween(chip, t, { BackgroundColor3 = skin.Accent, BackgroundTransparency = 0.6 })
            tween(chipStroke, t, { Color = skin.Accent })
        else
            chipText.Text = key and key.Name or "None"
            tween(chip, t, { BackgroundColor3 = skin.Surface2, BackgroundTransparency = 0 })
            tween(chipStroke, t, { Color = skin.Border })
        end
    end
    render(0)
    regAccent(win, el, function(t)
        render(t)
    end)

    el.conns[#el.conns + 1] = chip.MouseButton1Click:Connect(function()
        if not el.enabled then
            return
        end
        listening = not listening
        render()
    end)
    el.conns[#el.conns + 1] = UserInputService.InputBegan:Connect(function(input, gp)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if input.KeyCode == Enum.KeyCode.Escape then
                    key = nil
                else
                    key = input.KeyCode
                end
                render()
            elseif isPress(input) and not inside(chip, pointerPos(input)) then
                listening = false
                render()
            end
            return
        end
        if gp or not key or not el.enabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
            if mode == "Press" then
                safe(callback)
            elseif mode == "Toggle" then
                toggled = not toggled
                safe(callback, toggled)
            else
                holding = true
                safe(callback, true)
            end
        end
    end)
    el.conns[#el.conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if mode == "Hold" and holding and key and input.KeyCode == key then
            holding = false
            safe(callback, false)
        end
    end)
    el.conns[#el.conns + 1] = chip.MouseEnter:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0 })
    end)
    el.conns[#el.conns + 1] = chip.MouseLeave:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0.05 })
    end)

    local api = {}
    return export(api, {
        Get = function()
            return key
        end,
        Set = function(k)
            if typeof(k) == "EnumItem" then
                key = k
            else
                key = nil
            end
            render()
        end,
        SetMode = function(m)
            mode = normMode(m)
            toggled = false
            holding = false
        end,
        GetState = function()
            return toggled
        end,
        SetTitle = function(t)
            title.Text = tostring(t)
        end,
        SetEnabled = function(b)
            if b == false then
                listening = false
                render()
            end
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: COLORPICKER ]==--
function Elements:Colorpicker(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local callback = opts.Callback
    local color = (typeof(opts.Default) == "Color3") and opts.Default or Color3.fromRGB(160, 160, 160)
    local h, s, v = color:ToHSV()

    local row = makeRow(self, "Colorpicker", 44)
    local title = label({
        Text = tostring(opts.Title or "Color"),
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Parent = row,
    })
    local chip = make("TextButton", {
        Name = "Chip",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(44, 26),
        BackgroundColor3 = color,
        ZIndex = 5,
        Parent = row,
    }, { corner(4), stroke(skin.Border, 1, 0) })
    local setEnabled = attachDisable(win, el, row)

    local popup, popConns = nil, {}
    local svFrame, hueFrame, svCursor, hueCursor, hexLabel
    local dragMode = nil

    local function hexText()
        return string.format(
            "#%02X%02X%02X",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )
    end

    local function refresh(fire)
        color = Color3.fromHSV(h, s, v)
        chip.BackgroundColor3 = color
        if popup then
            svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
            hueCursor.Position = UDim2.new(0.5, 0, h, 0)
            hexLabel.Text = hexText()
        end
        if fire then
            safe(callback, color)
        end
    end

    local function pointerUpdate(p)
        if dragMode == "sv" and svFrame then
            local pos, size = svFrame.AbsolutePosition, svFrame.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then
                return
            end
            s = math.clamp((p.X - pos.X) / size.X, 0, 1)
            v = 1 - math.clamp((p.Y - pos.Y) / size.Y, 0, 1)
            refresh(true)
        elseif dragMode == "hue" and hueFrame then
            local pos, size = hueFrame.AbsolutePosition, hueFrame.AbsoluteSize
            if size.Y <= 0 then
                return
            end
            h = math.clamp((p.Y - pos.Y) / size.Y, 0, 1)
            refresh(true)
        end
    end

    local function closePopup()
        if not popup then
            return
        end
        local p = popup
        popup = nil
        dragMode = nil
        disconnectAll(popConns)
        pcall(function()
            p:Destroy()
        end)
        if win._closePopup == closePopup then
            win._closePopup = nil
        end
    end

    local function openPopup()
        if popup or not el.enabled then
            return
        end
        if win._closePopup then
            pcall(win._closePopup)
        end
        local cpos, csize = chip.AbsolutePosition, chip.AbsoluteSize
        local screen = win._gui.AbsoluteSize
        local x = math.clamp(cpos.X + csize.X - 220, 4, math.max(4, screen.X - 224))
        local y = cpos.Y + csize.Y + 4
        if y + 190 > screen.Y - 4 then
            y = cpos.Y - 190 - 4
        end
        y = math.max(4, y)

        popup = make("Frame", {
            Name = "ColorpickerPopup",
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(220, 190),
            BackgroundColor3 = skin.Surface,
            ZIndex = 100,
            Parent = win._gui,
        }, { corner(8), stroke(skin.Border, 1, 0.2) })
        local pscale = make("UIScale", { Scale = 0.95, Parent = popup })
        tween(pscale, 0.12, { Scale = 1 })

        -- SV-квадрат: цветная база + белый градиент (насыщенность) + чёрный градиент по вертикали (яркость)
        svFrame = make("Frame", {
            Name = "SV",
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.fromOffset(170, 160),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            Parent = popup,
        }, { corner(4) })
        local white = gradient(ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), 0)
        white.Transparency = NumberSequence.new(0, 1)
        make("Frame", {
            Name = "White",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = svFrame,
        }, { corner(4), white })
        local black = gradient(ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)), 90)
        black.Transparency = NumberSequence.new(1, 0)
        make("Frame", {
            Name = "Black",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Parent = svFrame,
        }, { corner(4), black })
        svCursor = make("Frame", {
            Name = "Cursor",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(s, 0, 1 - v, 0),
            Size = UDim2.fromOffset(10, 10),
            BackgroundTransparency = 1,
            ZIndex = 6,
            Parent = svFrame,
        }, { corner(5), stroke(Color3.new(1, 1, 1), 2, 0) })
        local svHit = make("TextButton", {
            Name = "Hit",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = svFrame,
        })

        -- Hue-слайдер
        local hueKeys = {}
        for i = 0, 6 do
            hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))
        end
        hueFrame = make("Frame", {
            Name = "Hue",
            Position = UDim2.fromOffset(190, 10),
            Size = UDim2.fromOffset(20, 160),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = popup,
        }, { corner(4), gradient(ColorSequence.new(hueKeys), 90) })
        hueCursor = make("Frame", {
            Name = "Cursor",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, h, 0),
            Size = UDim2.new(1, 4, 0, 4),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 6,
            Parent = hueFrame,
        }, { corner(2), stroke(Color3.new(0, 0, 0), 1, 0.3) })
        local hueHit = make("TextButton", {
            Name = "Hit",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = hueFrame,
        })

        hexLabel = label({
            Text = hexText(),
            Font = Fonts.Medium,
            TextSize = 11,
            TextColor3 = skin.TextDim,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.fromOffset(10, 172),
            Size = UDim2.fromOffset(200, 14),
            Parent = popup,
        })

        popConns[#popConns + 1] = svHit.InputBegan:Connect(function(input)
            if isPress(input) then
                dragMode = "sv"
                pointerUpdate(pointerPos(input))
            end
        end)
        popConns[#popConns + 1] = hueHit.InputBegan:Connect(function(input)
            if isPress(input) then
                dragMode = "hue"
                pointerUpdate(pointerPos(input))
            end
        end)
        popConns[#popConns + 1] = UserInputService.InputChanged:Connect(function(input)
            if dragMode and isMove(input) then
                pointerUpdate(pointerPos(input))
            end
        end)
        popConns[#popConns + 1] = UserInputService.InputEnded:Connect(function(input)
            if dragMode and isPress(input) then
                dragMode = nil
            end
        end)
        popConns[#popConns + 1] = UserInputService.InputBegan:Connect(function(input)
            if popup and isPress(input) then
                local p = pointerPos(input)
                if not inside(popup, p) and not inside(chip, p) then
                    closePopup()
                end
            end
        end)
        win._closePopup = closePopup
    end

    el.cleanup = closePopup
    el.conns[#el.conns + 1] = chip.MouseButton1Click:Connect(function()
        if popup then
            closePopup()
        else
            openPopup()
        end
    end)
    el.conns[#el.conns + 1] = chip.MouseEnter:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0 })
    end)
    el.conns[#el.conns + 1] = chip.MouseLeave:Connect(function()
        tween(row, 0.12, { BackgroundTransparency = 0.05 })
    end)

    local api = {}
    return export(api, {
        Get = function()
            return color
        end,
        Set = function(c)
            if typeof(c) ~= "Color3" then
                return
            end
            local nh, ns, nv = c:ToHSV()
            -- у серых цветов оттенок не определён — сохраняем прежний
            if ns > 0.001 and nv > 0.001 then
                h = nh
            end
            s, v = ns, nv
            refresh(false)
        end,
        SetTitle = function(t)
            title.Text = tostring(t)
        end,
        SetEnabled = function(b)
            if b == false then
                closePopup()
            end
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: PARAGRAPH ]==--
function Elements:Paragraph(opts)
    opts = opts or {}
    local win, el = beginElement(self)
    local skin = win._skin
    local titleText = tostring(opts.Title or "")
    local contentText = tostring(opts.Content or "")

    local row = make("Frame", {
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = skin.Surface2,
        BackgroundTransparency = 0.35,
        LayoutOrder = nextOrder(self._ctx),
        Parent = self._ctx.frame,
    }, {
        corner(6),
        make("UIPadding", {
            PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        }),
        make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local title = label({
        Text = titleText,
        Font = Fonts.Bold,
        TextSize = 14,
        TextColor3 = skin.Text,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Visible = (titleText ~= ""),
        Parent = row,
    })
    local content = label({
        Text = contentText,
        Font = Fonts.Regular,
        TextSize = 13,
        TextColor3 = skin.TextDim,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = (contentText ~= ""),
        Parent = row,
    })
    local setEnabled = attachDisable(win, el, row)

    local api = {}
    return export(api, {
        Get = function()
            return titleText, contentText
        end,
        Set = function(t)
            contentText = tostring(t)
            content.Text = contentText
            content.Visible = (contentText ~= "")
        end,
        SetTitle = function(t)
            titleText = tostring(t)
            title.Text = titleText
            title.Visible = (titleText ~= "")
        end,
        SetContent = function(t)
            contentText = tostring(t)
            content.Text = contentText
            content.Visible = (contentText ~= "")
        end,
        SetEnabled = function(b)
            setEnabled(b)
        end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ ЭЛЕМЕНТ: DIVIDER ]==--
function Elements:Divider()
    local win, el = beginElement(self)
    local skin = win._skin
    local row = make("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(self._ctx),
        Parent = self._ctx.frame,
    })
    make("Frame", {
        Name = "Line",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = skin.Border,
        BackgroundTransparency = 0.55,
        Parent = row,
    })
    local api = {}
    return export(api, {
        Get = function()
            return nil
        end,
        Set = function() end,
        SetEnabled = function() end,
        Destroy = function()
            destroyElement(win, el, row)
        end,
    })
end

--==[ МЕТОДЫ ВКЛАДКИ ]==--
function TabMethods:Select()
    self._win:SelectTab(self)
end

--==[ ОКНО (Window) ]==--
local Window = {}
Window.__index = Window

function Window:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return
    end
    local skin = self._skin
    skin.Accent = color
    skin.AccentSoft = Color3.new(lerp(color.R, 1, 0.35), lerp(color.G, 1, 0.35), lerp(color.B, 1, 0.35))
    for _, fn in pairs(self._accent) do
        pcall(fn, 0.15)
    end
end

function Window:SelectTab(index)
    local target
    if type(index) == "number" then
        target = self._tabs[index]
    elseif type(index) == "table" then
        target = index
    elseif type(index) == "string" then
        for _, t in ipairs(self._tabs) do
            if t.Title == index then
                target = t
                break
            end
        end
    end
    if not target or target == self._currentTab then
        return
    end
    local first = (self._currentTab == nil)
    self._currentTab = target
    for _, t in ipairs(self._tabs) do
        t._setActive(t == target, first)
        t.Page.Visible = (t == target)
    end
    if self._closePopup then
        pcall(self._closePopup)
    end
    target.Page.Position = UDim2.fromOffset(0, first and 0 or 10)
    tween(target.Page, 0.18, { Position = UDim2.fromOffset(0, 0) })
end

function Window:Tab(opts)
    opts = opts or {}
    local skin = self._skin
    local index = #self._tabs + 1
    local titleText = tostring(opts.Title or ("Tab " .. index))

    local btn = make("TextButton", {
        Name = "Tab_" .. index,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = skin.Surface2,
        BackgroundTransparency = 1,
        LayoutOrder = index,
        Parent = self._tabList,
    }, { corner(6) })
    local _, setIconColor = buildIcon(btn, opts.Icon, skin.TextDim)
    local titleLabel = label({
        Text = titleText,
        Font = Fonts.Medium,
        TextSize = 13,
        TextColor3 = skin.TextDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -48, 1, 0),
        Parent = btn,
    })
    local bar = make("Frame", {
        Name = "Bar",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 20),
        BackgroundColor3 = skin.Accent,
        BackgroundTransparency = 1,
        Parent = btn,
    }, { corner(2) })

    local page = make("ScrollingFrame", {
        Name = "Page_" .. index,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = skin.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self._content,
    }, {
        make("UIPadding", {
            PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20),
            PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20),
        }),
        make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local pageCtx = newCtx(page)
    local tab = setmetatable({
        _win = self,
        _ctx = pageCtx,
        _baseCtx = pageCtx,
        _isTab = true,
        Title = titleText,
        Index = index,
        Page = page,
        Button = btn,
    }, TabMT)

    local active = false
    tab._setActive = function(a, instant)
        active = a
        local t = instant and 0 or 0.12
        tween(btn, t, { BackgroundTransparency = a and 0 or 1 })
        tween(bar, t, { BackgroundTransparency = a and 0 or 1 })
        tween(titleLabel, t, { TextColor3 = a and skin.Text or skin.TextDim })
        setIconColor(a and skin.AccentSoft or skin.TextDim)
    end

    self._conns[#self._conns + 1] = btn.MouseEnter:Connect(function()
        if not active then
            tween(btn, 0.12, { BackgroundTransparency = 0.6 })
        end
    end)
    self._conns[#self._conns + 1] = btn.MouseLeave:Connect(function()
        if not active then
            tween(btn, 0.12, { BackgroundTransparency = 1 })
        end
    end)
    self._conns[#self._conns + 1] = btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    regAccent(self, nil, function(t)
        tween(bar, t, { BackgroundColor3 = skin.Accent })
        if active then
            setIconColor(skin.AccentSoft)
        end
    end)

    self._tabs[index] = tab
    if index == 1 then
        self:SelectTab(1)
    end
    return tab
end

function Window:SetVisible(v)
    if self._destroyed then
        return
    end
    v = (v == true)
    self._visible = v
    if self._closePopup then
        pcall(self._closePopup)
    end
    if v then
        self._minimized = false
        self._pill.Visible = false
        -- Если окно было развёрнуто на весь экран до скрытия — вернуть fullscreen-размер
        if self._maximized then
            self._holder.Size = UDim2.fromScale(1, 1)
            self._holder.Position = UDim2.fromScale(0.5, 0.5)
        end
        self._animateIn()
    else
        self._pill.Visible = false
        self._minimized = false
        self._animateOut(function()
            if not self._visible and not self._destroyed then
                self._holder.Visible = false
            end
        end)
    end
end

function Window:Notify(opts)
    if self._destroyed then
        return nil
    end
    opts = opts or {}
    local skin = self._skin
    local duration = tonumber(opts.Duration) or 4

    -- максимум 4 уведомления одновременно
    while #self._notes >= 4 do
        local oldest = table.remove(self._notes, 1)
        oldest.dismiss(true)
    end

    self._noteOrder = self._noteOrder + 1
    local wrap = make("Frame", {
        Name = "Note",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self._noteOrder,
        Parent = self._noteHolder,
    })
    local cardStroke = stroke(skin.Border, 1, 1)
    local card = make("Frame", {
        Name = "Card",
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = skin.Surface2,
        BackgroundTransparency = 1,
        Parent = wrap,
    }, { corner(6), cardStroke })
    local scale = make("UIScale", { Scale = 0.9, Parent = card })
    local inner = make("Frame", {
        Name = "Inner",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    }, {
        make("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        }),
        make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local titleText = tostring(opts.Title or "")
    local contentText = tostring(opts.Content or "")
    local titleLabel = label({
        Text = titleText,
        Font = Fonts.Bold,
        TextSize = 14,
        TextColor3 = skin.Text,
        TextTransparency = 1,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Visible = (titleText ~= ""),
        Parent = inner,
    })
    local contentLabel = label({
        Text = contentText,
        Font = Fonts.Regular,
        TextSize = 13,
        TextColor3 = skin.TextDim,
        TextTransparency = 1,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Visible = (contentText ~= ""),
        Parent = inner,
    })
    local bar = make("Frame", {
        Name = "Progress",
        Position = UDim2.new(0, 8, 1, -4),
        Size = UDim2.new(1, -16, 0, 2),
        BackgroundColor3 = skin.Accent,
        Parent = card,
    }, { corner(1) })

    local dismissed = false
    local entry = {}
    local function dismiss(instant)
        if dismissed then
            return
        end
        dismissed = true
        for i, e in ipairs(self._notes) do
            if e == entry then
                table.remove(self._notes, i)
                break
            end
        end
        if instant then
            pcall(function()
                wrap:Destroy()
            end)
            return
        end
        tween(card, 0.3, { Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1 })
        tween(scale, 0.3, { Scale = 0.9 })
        tween(titleLabel, 0.3, { TextTransparency = 1 })
        tween(contentLabel, 0.3, { TextTransparency = 1 })
        tween(cardStroke, 0.3, { Transparency = 1 })
        tween(bar, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.3, function()
            pcall(function()
                wrap:Destroy()
            end)
        end)
    end
    entry.dismiss = dismiss
    self._notes[#self._notes + 1] = entry

    -- появление
    tween(card, 0.25, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.05 })
    tween(scale, 0.25, { Scale = 1 })
    tween(titleLabel, 0.25, { TextTransparency = 0 })
    tween(contentLabel, 0.25, { TextTransparency = 0 })
    tween(cardStroke, 0.25, { Transparency = 0.2 })
    -- progress-bar
    tween(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
    task.delay(duration, function()
        if not self._destroyed then
            dismiss(false)
        end
    end)

    return {
        Dismiss = function()
            dismiss(false)
        end,
    }
end

function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    if self._closePopup then
        pcall(self._closePopup)
    end
    disconnectAll(self._conns)
    for _, group in ipairs(self._groups) do
        disconnectAll(group)
    end
    pcall(function()
        self._gui:Destroy()
    end)
end

--==[ Flux:Window — создание окна ]==--
function Flux:Window(config)
    config = config or {}
    local skin = {}
    for k, v in pairs(Skin) do
        skin[k] = v
    end

    local win = setmetatable({
        _skin = skin,
        _conns = {},
        _groups = {},
        _accent = {},
        _accentSeq = 0,
        _tabs = {},
        _notes = {},
        _noteOrder = 0,
        _visible = true,
        _minimized = false,
        _maximized = false,
        _destroyed = false,
        _currentTab = nil,
        Config = config,
    }, Window)

    --== ScreenGui ==--
    local gui = make("ScreenGui", {
        Name = "FluxUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 200,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    mount(gui)
    win._gui = gui

    --== Holder: контейнер окна (позиция, размер, масштаб) ==--
    local size = (typeof(config.Size) == "UDim2") and config.Size or UDim2.fromOffset(760, 520)
    local holder = make("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundTransparency = 1,
        Parent = gui,
    })
    local holderScale = make("UIScale", { Scale = 0.9, Parent = holder })
    win._holder = holder

    -- Тень (соседний с Root элемент, чтобы лежать позади)
    local shadow = make("Frame", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = holder,
    }, { corner(18) })

    -- Root: CanvasGroup, чтобы вместе с фоном плавно появлялось всё содержимое
    local root = make("CanvasGroup", {
        Name = "Root",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = skin.Bg,
        BackgroundTransparency = 0.05,
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = holder,
    }, { corner(12), stroke(skin.Border, 1, 0.35) })

    -- Подсветка сверху
    local topGlow = make("Frame", {
        Name = "TopGlow",
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = skin.Accent,
        ZIndex = 10,
        Parent = root,
    }, { gradient(ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), 0) })
    topGlow:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })

    --== HEADER ==--
    local header = make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = root,
    })
    make("Frame", {
        Name = "Divider",
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = skin.Border,
        BackgroundTransparency = 0.3,
        Parent = header,
    })
    local logoGradient = gradient(ColorSequence.new(skin.Accent, skin.AccentSoft), 45)
    make("Frame", {
        Name = "Logo",
        Position = UDim2.fromOffset(16, 13),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = header,
    }, { corner(4), logoGradient })

    local titleText = tostring(config.Title or "Flux")
    local subText = tostring(config.SubTitle or "")
    if subText ~= "" then
        label({
            Name = "Title",
            Text = titleText,
            Font = Fonts.Semi,
            TextSize = 14,
            TextColor3 = skin.Text,
            Position = UDim2.fromOffset(50, 7),
            Size = UDim2.new(1, -170, 0, 18),
            Parent = header,
        })
        label({
            Name = "SubTitle",
            Text = subText,
            Font = Fonts.Regular,
            TextSize = 11,
            TextColor3 = skin.TextDim,
            Position = UDim2.fromOffset(50, 25),
            Size = UDim2.new(1, -170, 0, 14),
            Parent = header,
        })
    else
        label({
            Name = "Title",
            Text = titleText,
            Font = Fonts.Semi,
            TextSize = 14,
            TextColor3 = skin.Text,
            Position = UDim2.fromOffset(50, 0),
            Size = UDim2.new(1, -170, 1, 0),
            Parent = header,
        })
    end

    drag(holder, header, win._conns, function()
        return not win._maximized
    end)

    -- Кнопки-точки
    local function dot(xOff, color, onClick)
        local hit = make("TextButton", {
            Name = "Dot",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOff, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = header,
        })
        local d = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = color,
            Parent = hit,
        }, { corner(5) })
        local sc = make("UIScale", { Parent = d })
        local hovered = false
        win._conns[#win._conns + 1] = hit.MouseEnter:Connect(function()
            hovered = true
            tween(sc, 0.12, { Scale = 1.15 })
        end)
        win._conns[#win._conns + 1] = hit.MouseLeave:Connect(function()
            hovered = false
            tween(sc, 0.12, { Scale = 1 })
        end)
        win._conns[#win._conns + 1] = hit.MouseButton1Down:Connect(function()
            tween(sc, 0.08, { Scale = 0.9 })
        end)
        win._conns[#win._conns + 1] = hit.MouseButton1Up:Connect(function()
            tween(sc, 0.08, { Scale = hovered and 1.15 or 1 })
        end)
        win._conns[#win._conns + 1] = hit.MouseButton1Click:Connect(function()
            safe(onClick)
        end)
        return hit
    end

    --== SIDEBAR ==--
    local sidebar = make("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(0, 180, 1, -48),
        BackgroundTransparency = 1,
        Parent = root,
    })
    make("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = skin.Border,
        BackgroundTransparency = 0.5,
        Parent = sidebar,
    })
    local tabList = make("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -1, 1, -34),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar,
    }, {
        make("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        }),
        make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    win._tabList = tabList

    local statusLabel = label({
        Name = "Status",
        Text = "",
        Font = Fonts.Regular,
        TextSize = 11,
        TextColor3 = skin.TextDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 14, 1, -28),
        Size = UDim2.new(1, -28, 0, 24),
        Parent = sidebar,
    })

    --== CONTENT ==--
    local content = make("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(180, 48),
        Size = UDim2.new(1, -180, 1, -48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = root,
    })
    win._content = content

    --== ПИЛЮЛЯ (свёрнутое окно) ==--
    local pill = make("Frame", {
        Name = "Pill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 12),
        Size = UDim2.fromOffset(200, 32),
        BackgroundColor3 = skin.Surface,
        BackgroundTransparency = 0.05,
        Visible = false,
        Parent = gui,
    }, { corner(16), stroke(skin.Border, 1, 0.3) })
    local pillScale = make("UIScale", { Scale = 0.9, Parent = pill })
    local pillDot = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = skin.Accent,
        Parent = pill,
    }, { corner(4) })
    label({
        Text = titleText,
        Font = Fonts.Semi,
        TextSize = 13,
        TextColor3 = skin.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -44, 1, 0),
        Parent = pill,
    })
    local pillBtn = make("TextButton", {
        Name = "Hit",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = pill,
    })
    win._pill = pill

    --== NOTIFY HOLDER ==--
    local noteHolder = make("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -40),
        BackgroundTransparency = 1,
        Parent = gui,
    }, {
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        }),
    })
    win._noteHolder = noteHolder

    --== Анимации окна ==--
    win._animateIn = function()
        holder.Visible = true
        holderScale.Scale = 0.9
        root.GroupTransparency = 1
        shadow.BackgroundTransparency = 1
        tween(holderScale, 0.28, { Scale = 1 })
        tween(root, 0.28, { GroupTransparency = 0 })
        tween(shadow, 0.28, { BackgroundTransparency = win._maximized and 1 or 0.85 })
    end
    win._animateOut = function(done)
        tween(holderScale, 0.2, { Scale = 0.9 })
        tween(root, 0.2, { GroupTransparency = 1 })
        tween(shadow, 0.2, { BackgroundTransparency = 1 })
        task.delay(0.2, function()
            if done then
                done()
            end
        end)
    end

    local function minimize()
        if win._minimized or not win._visible then
            return
        end
        win._minimized = true
        if win._closePopup then
            pcall(win._closePopup)
        end
        win._animateOut(function()
            if win._minimized and not win._destroyed then
                holder.Visible = false
            end
        end)
        pill.Visible = true
        pillScale.Scale = 0.9
        tween(pillScale, 0.2, { Scale = 1 })
    end
    local function restore()
        if not win._minimized then
            return
        end
        win._minimized = false
        pill.Visible = false
        win._animateIn()
    end
    local function toggleMaximize()
        if win._maximized then
            win._maximized = false
            tween(holder, 0.28, { Size = win._normalSize, Position = win._normalPos })
            tween(shadow, 0.28, { BackgroundTransparency = 0.85 })
        else
            win._normalSize = holder.Size
            win._normalPos = holder.Position
            win._maximized = true
            tween(holder, 0.28, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5) })
            tween(shadow, 0.28, { BackgroundTransparency = 1 })
        end
    end

    dot(-14, Color3.fromRGB(220, 80, 90), function()
        win:SetVisible(false)
    end)
    dot(-34, Color3.fromRGB(100, 200, 120), toggleMaximize)
    dot(-54, Color3.fromRGB(240, 190, 90), minimize)

    win._conns[#win._conns + 1] = pillBtn.MouseButton1Click:Connect(restore)
    win._conns[#win._conns + 1] = pillBtn.MouseEnter:Connect(function()
        tween(pillScale, 0.12, { Scale = 1.04 })
    end)
    win._conns[#win._conns + 1] = pillBtn.MouseLeave:Connect(function()
        tween(pillScale, 0.12, { Scale = 1 })
    end)

    --== Акцент: окно, лого, пилюля ==--
    regAccent(win, nil, function(t)
        tween(topGlow, t, { BackgroundColor3 = skin.Accent })
        tween(pillDot, t, { BackgroundColor3 = skin.Accent })
        logoGradient.Color = ColorSequence.new(skin.Accent, skin.AccentSoft)
    end)

    --== Статус (RenderStepped, раз в 0.25 c) ==--
    if config.Status ~= nil then
        local acc = 0
        local function updateStatus()
            local st = config.Status
            local text = ""
            if type(st) == "function" then
                local ok, r = pcall(st)
                text = ok and tostring(r) or ""
            elseif st ~= nil then
                text = tostring(st)
            end
            statusLabel.Text = text
        end
        updateStatus()
        win._conns[#win._conns + 1] = RunService.RenderStepped:Connect(function(dt)
            acc = acc + dt
            if acc >= 0.25 then
                acc = 0
                updateStatus()
            end
        end)
    end

    --== Опциональная горячая клавиша показа/скрытия ==--
    if typeof(config.ToggleKey) == "EnumItem" then
        win._conns[#win._conns + 1] = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == config.ToggleKey then
                win:SetVisible(not (win._visible and not win._minimized))
            end
        end)
    end

    -- Открытие окна
    win._animateIn()

    return win
end

return Flux
