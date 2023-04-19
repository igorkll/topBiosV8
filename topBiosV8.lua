--юзал этот минификатор - https://codentools.com/lua-minifier
--гавнокод, котому что нужно чтобы весило мало
--тут одни и теже переменные используються по многу раз
--из за этого bios может быть версмя не стабилен
--[[
    биос поддерживает новый стандарт загрузки "LGC 2023-A"
    данный bios полностью соответствует этому стандарту, и вы можете его изучать для создания своего
    для соответствия данному стандарту загрузки необходимо:
        кастомный shotdown:
            вызов computer.shutdown("bios") должен перезагрузить компьютер в меню bios
            вызов computer.shutdown("fast") должен перезагрузить компьютер без предложения зайти в меню bios
    
        все методы(кроме shutdown) принимаюшие значения должны преверять их валидность!

        приоритет загрузки(вы можете сделать меню с настройкой приоритета, или как хотите, это лиш рекомендации)
            если в памяти bios лежит url то загрузка должна производиться с него
            если же url - nil то загрузка должна производиться с запомненого адреса диска

            если и такового нет(или путь nil) или загрузка с url не удалась,
            то bios должен вернуться на окно c предложениям открыть меню bios(опционально, вы можете сделать выбор приоритета)
            если же пользователь не открыл bios то заного попробовать загрузиться по приаритету

        getBootEeprom - обязателен
            должен вернуть строчку с адресом eeprom чипа с которого производилась загрузка bios
            работа метода не должна поменяться даже если eeprom был изьят или заменен
            (всеравно метод должен возврашяться адрес загрузочного eeprom)

        setBootAddress - обязателен
            должен записать строчку в память и в значения getBootAddress
            может принять nil что сотрет строчку из памяти
        getBootAddress - обязателен
            возврашяет строчку с адресом жесткого диска,
            после вызова setBootAddress, getBootAddress должен сразу начать возврашять новое значения
            если в памяти bios лежит другой адрес, то данный метод всеравно должен возврашять адрес диска
            с которого в данный момент производиться загрузка

            однако при вызове setBootAddress возврашяемая строка должна сразу измениться
            на новый адрес а так же сохраниться в память(если такавая имееться)

            в случаи с url boot метод должен возврашять адрес который помнит bios, и некакого значения по умалчанию

        setBootFile - обязателен
            должен записать строчку в память и в значения getBootFile
            может принять nil что сотрет строчку из памяти
        getBootFile - обязателен
            должен вернуть файл с которого была произведена загрузка,
            после вызова setBootFile, getBootFile должен сразу начать возврашять новое значения
            если в памяти bios лежит другой путь, то данный метод всеравно должен возврашять путь до файла
            с которого в данный момент производиться загрузка

            однако при вызове setBootFile возврашяемый путь должен сразу измениться
            на новый, а так же сохраниться в память(если такавая имееться)

            в случаи с url boot метод должен возврашять путь который помнит bios, и некакого значения по умалчанию


        getBootGpu - обязателен если bios поддерживает вывод на экран
            если же вывод на экран не поддерживаеться то данного метода быть не должно
            должен вернуть строчку с адресом видеокарты которая использовалась для вывода изображения при работе bios
            если таковой нет(например компьютер не имеет видеокарты) то должен вернуть nil
            работа метода не должна поменяться даже если gpu была изьята или заменена
            (всеравно метод должен возврашяться адрес загрузочной gpu)

        getBootScreen - обязателен если bios поддерживает вывод на экран
            если же вывод на экран не поддерживаеться то данного метода быть не должно
            должен вернуть строчку с адресом монитора который использовался для вывода изображения при запуске bios
        setBootScreen - опционален, должен устонавливать адрес монитора
            на котором bios будет загружаться в следуюший раз, при этом после вызова setBootScreen,
            getBootScreen должен начать возврашять обновленное значения

            метод обязательно должен присутствовать если в меню если возможность устоновить монитор
            если есть метод setBootScreen то обязательно должна быть проверка на нажатия(с того ли монитора они идут)
            и проверка на клавиатуру(прицеплина ли эта кливиатура к этому монитору)

        если bios поддерживает загрузку с url то должны присутствать следуюшие методы(даже если сейчас загрузка идет не по url):
            getBootUrl
                должен возврашять url с которого производиться загрузка
                если таковой не установлен, то должен вернуть nil

                если в данный момент производиться загрузка по url
                то данный метод должен возврашять url
                с которого в данный момент производиться загрузка, даже если в памяти bios лежит другой url

                однако после вызова setBootUrl, getBootUrl должен сразу начать возврашять новое значения

                если в данный момент загрузка идет не по url то просто должен возврашять адрес url который находиться в памяти bios

            setBootUrl
                должен устанавливать загрузочный url
                может принять nil
]]

local _checkArg, str_string, str_nil, str_initlua, str_kernel, str_lua, str_seturlboot, str_lifeurlboot, str_sbp, str_sbf, str_empty, str_lifeboot, str_openOSonline, str_updateUrl, str_defaultSettings, str_settings, str_biosname, str_exit, str_nointernetcard, proxy, list, invoke, TRUE =
       checkArg, "string", "nil", "init.lua", "boot/kernel/", "Lua Shell", "Set Url Boot", "Life Url Boot", "Select Boot Priority", "Select Boot Fs", "", "Life Boot", "https://raw.githubusercontent.com/igorkll/topBiosV8/main/openOSonline.lua", "https://raw.githubusercontent.com/igorkll/topBiosV8/main/topBiosV8.bin", "{u='',e=true,k=true,j=true,f=false}", "Settings", "Top Bios V8", "exit", "no internet-card, urlboot is not available", component.proxy, component.list, component.invoke, true

local eeprom, boot_eeprom, _computer, _pcall, resX, resY, --не забуть запитую
screen, eeprom_data, selected1, empty, event, code, str, char, err,
tryUrlBoot, saveWithSplash, reverseColor, setBackground, setForeground, hpath, haddr, old_laddr, old_lpath,
tryBoot, gIsPal, col, isPal, tmp1, setPaletteColor, internet, gpu, boot_gpu, refresh
=
proxy(list"eep"()), list"eep"(), computer, pcall, 50, 16

function refresh()
    internet = proxy(list"int"() or str_empty)
    gpu = proxy(list"gp"() or str_empty)
    screen = list"scr"()
    if gpu and screen then
        setBackground, setForeground, setPaletteColor =
        gpu.setBackground, gpu.setForeground, gpu.setPaletteColor
        
        gpu.bind(screen)
        gpu.setDepth(1) --reset pallete
        gpu.setDepth(math.min(gpu.maxDepth(), 4))

        if gpu.getDepth() > 3 then
            --4 depth
            setPaletteColor(0, eeprom_data.w and -1 or 0x000000)
            setPaletteColor(1, eeprom_data.w and 0x000000 or -1)
            setPaletteColor(2, 0x888888)
            gIsPal = 1
        end
    
        gpu.setResolution(resX, resY)
    
        invoke(screen, "turnOn")
    end

    boot_gpu = gpu and gpu.address
end

::retry2::
if not pcall(function()
    eeprom_data = load("return " .. eeprom.getData())()
end) then
    eeprom.setData(str_defaultSettings)
    goto retry2
end

function reverseColor()
    --setBackground(setForeground(gpu.getBackground())) --unsupported pallete
    col, isPal = gpu.getBackground()
    gpu.setBackground(gpu.getForeground())
    gpu.setForeground(col, isPal)
end

local clear, drawStr, pullSignal, save, beforeBoot, setColor, rebootmode, bm_fast, bm_bios, shutdown = function()
    gpu.fill(1, 1, resX, resY, " ")
end, function(str, posY, invert)
    if invert then reverseColor() end
    gpu.set(math.floor(resX / 2 - #str / 2) + 1, posY, str)
    if invert then reverseColor() end
end, function(wait)
    event, empty, char, code = _computer.pullSignal(wait)
    if event == "component_added" or event == "component_removed" then
        refresh()
    end
end, function ()
    str = "{"
    for k, v in pairs(eeprom_data) do
        if type(v) == "string" then
            str = str .. k .. "='" .. v .. "',"
        else
            str = str .. k .. "=" .. tostring(v) .. ","
        end
    end
    _pcall(eeprom.setData, str .. "}")
end, function ()
    gpu.setDepth(1) --reset pallete
    gpu.setDepth(gpu.maxDepth())

    setBackground(0)
    setForeground(-1)
end, function(num)
    if gIsPal then
        if num == 0 then
            setBackground(1, TRUE)
            setForeground(0, TRUE)
        elseif num == 1 then
            setBackground(1, TRUE)
            setForeground(2, TRUE)
        end
    else
        setBackground(eeprom_data.w and 0 or -1)
        setForeground(eeprom_data.w and -1 or 0)
    end
end,
eeprom.getLabel(), "__fast", "__bios", _computer.shutdown

eeprom.setLabel(str_biosname)
refresh()

---------------- boot standart "LGC 2023-A"

----main methods
function _computer.shutdown(mode)
    if mode == "bios" then
        _pcall(eeprom.setLabel, bm_bios)
    elseif mode == "fast" then
        _pcall(eeprom.setLabel, bm_fast)
    end
    shutdown(mode)
end

function _computer.getBootUrl()
    if eeprom_data.u == str_empty then return end
    return eeprom_data.u
end
function _computer.setBootUrl(url)
    _checkArg(1, url, str_string, str_nil)
    eeprom_data.u = url or str_empty
    save()
end

----getters
function _computer.getBootEeprom()
    return boot_eeprom
end
function _computer.getBootGpu()
    return boot_gpu
end
function _computer.getBootScreen()
    return screen
end

----default methods
function _computer.getBootAddress()
    return haddr or eeprom_data.a
end
function _computer.setBootAddress(address)
    _checkArg(1, address, str_string, str_nil)
    eeprom_data.a, haddr = address, address
    save()
end


function _computer.getBootFile()
    return hpath or eeprom_data.p
end
function _computer.setBootFile(file)
    _checkArg(1, file, str_string, str_nil)
    eeprom_data.p, hpath = file, file
    save()
end

---------------- ----------------

local menu, splash, input, boot, urlboot, bootmenu = function(title, strs, current)
    setColor(0)
    clear()
    drawStr(title, 2, not gIsPal)
    ::LOOP::
        setColor(1)
        for i, str in ipairs(strs) do
            drawStr((" "):rep(46), i + 3, i == current)
            drawStr(str, i + 3, i == current)
        end

        pullSignal()
        if event == "key_down" then
            if code == 28 then
                return current
            end
            if code == 208 and current < #strs then
                current = current + 1
            end
            if code == 200 and current > 1 then
                current = current - 1
            end
        end
    goto LOOP
end, function (title, wait)
    if not gpu then return end

    setColor(0)
    clear()
    drawStr(title, 2)
    while wait do
        setColor(1)
        drawStr("press enter to continue", 4)

        pullSignal()
        if event == "key_down" and code == 28 then
            break
        end
    end
end, function(title, lstr)
    str = lstr or str_empty
    ::LOOP::
        clear()
        setColor(0)
        drawStr(title, 2)
        setColor(1)
        drawStr(str .. "_", 4)

        pullSignal()
        if event == "key_down" then
            if code == 28 then
                return str
            elseif code == 14 then
                str = str:sub(1, -2)
            elseif char > 31 and char < 127 then
                str = str .. string.char(char)
            end
        elseif event == "clipboard" then
            str = str .. char
        end
    goto LOOP
end, function (addr, path)
    ---------------- load boot file
    empty, str, char, err, haddr, hpath = proxy(addr), str_empty, str_empty, F, addr, path
    event, err = empty.open(path, "rb")
    if event then
        repeat
            str = str .. char
            char = empty.read(event, math.huge)
        until not char
        --empty.close(event) --само закроеться когда оно выгрузиться
        code, err = load(str, "=" .. path)
    end
    if err then
        return err
    end

    ----------------run

    beforeBoot()
    err = debug.traceback
    assert(xpcall(code, err))
    shutdown()
end, function (url)
    empty, str, err = internet.request(url), str_empty, "Unvalid Address"
    while empty do
        char, err = empty.read(math.huge)
        if char then
            str = str .. char
        else
            break
        end
    end

    if err then return err end
    code, err = load(str, "=" .. url)
    if err then return err end

    ----------------run

    beforeBoot()
    err = debug.traceback
    assert(xpcall(code, err))
    shutdown()
end

--------------------- main funcs

function bootmenu() --is local
    err, hpath, haddr, old_laddr, old_lpath = {"none"}, {}, 1, eeprom_data.a, eeprom_data.p
    for address in list"file" do
        table.insert(err, address:sub(1, 5) .. ":" .. (invoke(address, "getLabel") or "unknown"))
        hpath[#err] = address
        if address == eeprom_data.a then
            haddr = #err
        end
    end
    selected1 = menu(str_sbf, err, haddr)
    if hpath[selected1] then
        if eeprom_data.a ~= hpath[selected1] then
            eeprom_data.p = F
        end
        eeprom_data.a = hpath[selected1]

        err, haddr = {}, 1
        if invoke(eeprom_data.a, "exists", str_initlua) then
            err = {str_initlua}
        end
        for k, v in ipairs(invoke(eeprom_data.a, "list", str_kernel) or {}) do
            char = str_kernel .. v
            table.insert(err, char)
            if char == eeprom_data.p then
                haddr = #err
            end
        end
        if #err > 0 then
            selected1 = menu("select file", err, haddr)
            eeprom_data.p = err[selected1]
        else
            splash("no boot files on this fs", 1)
            eeprom_data.a, eeprom_data.p = old_laddr, old_lpath
            return 1
        end
    else
        eeprom_data.a, eeprom_data.p = F, F
        return 1
    end
end

function tryBoot(laddr, lpath) --is local
    err = " (" .. laddr:sub(1, 4) .. ", " .. lpath .. ") "
    splash("booting" .. err)
    

    str = boot(laddr, lpath)
    if str then
        splash("boot-error" .. err .. str, 1)
    end
end

function tryUrlBoot(url) --is local
    if not internet then splash(str_nointernetcard, 1) return end
    splash("url booting")

    str = urlboot(url)
    if str then
        splash("error-urlboot: " .. str, 1)
    end
end

function saveWithSplash() --is local
    splash"saving"
    save()
end

--------------------- main

if eeprom_data.k then
    _computer.beep"."
end

if gpu and rebootmode ~= bm_fast and not eeprom_data.f then
    splash"press ALT to open the bios menu"

    selected1 = F
    if rebootmode == bm_bios then
        selected1 = 1
    else
        for i = 0, 7 do
            pullSignal(.1)
            if event == "key_down" and code == 56 then
                selected1 = 1
                break
            end
        end
    end

    while selected1 do
        selected1 = menu(str_biosname, {str_sbp, str_sbf, str_lifeboot, "Internet Utiles", "Shutdown", "Reset", str_lua, str_settings, str_exit}, selected1)

        if selected1 == 1 then
            --если b - true, то выставленный url приоритетние
            eeprom_data.b = menu(str_sbp, {"Fs", "Url"}, eeprom_data.b and 2 or 1) == 2
            saveWithSplash()
        elseif selected1 == 2 then
            bootmenu()
            selected1 = 2
            saveWithSplash()
        elseif selected1 == 3 then
            tmp1 = bootmenu()
            str, err = eeprom_data.a, eeprom_data.p
            selected1, eeprom_data.a, eeprom_data.p = 3, old_laddr, old_lpath
            if not tmp1 then tryBoot(str, err) end
        elseif selected1 == 4 then
            if not internet then splash(str_nointernetcard, 1) end --но вы всеравно сможете изменить настройки
            selected1 = 1
            while 1 do
                selected1 = menu("Internet Utiles", {str_seturlboot, str_lifeurlboot, "set openOSonline at urlboot", "run openOSonline", "run saved url", str_exit}, selected1)
                if selected1 == 1 then
                    eeprom_data.u = input(str_seturlboot, eeprom_data.u)
                    saveWithSplash()
                elseif selected1 == 2 then
                    tryUrlBoot(input(str_lifeurlboot))
                elseif selected1 == 3 then
                    eeprom_data.u = str_openOSonline
                    saveWithSplash()
                elseif selected1 == 4 then
                    tryUrlBoot(str_openOSonline)
                elseif selected1 == 5 then
                    tryUrlBoot(eeprom_data.u)
                elseif selected1 == 6 then
                    break
                end                
            end
            selected1 = 4
        elseif selected1 == 5 then
            shutdown()
        elseif selected1 == 6 then
            splash"resetting"
            eeprom.setData(str_defaultSettings)
            shutdown(1)
        elseif selected1 == 7 then
            haddr = F
            while 1 do
                haddr = input(str_lua, haddr)
                if haddr == str_exit or haddr == str_empty then
                    break
                end
                code, err = load(haddr)
                if not code then
                    splash(err, 1)
                else
                    code, err = pcall(code)
                    if not code then
                        splash(err, 1)
                    end
                end
            end
        elseif selected1 == 8 then
            selected1 = 1
            while 1 do
                selected1 = menu(str_settings,
                    {"beep on start: " .. tostring(eeprom_data.k),
                    "allow boot auto-assignments: " .. tostring(eeprom_data.e),
                    "allow set urlboot by auto-assignments: " .. tostring(eeprom_data.j),
                    "theme: " .. eeprom_data.w and "black" or "white",
                    "fastboot: " .. tostring(eeprom_data.f),
                    str_exit}, selected1)
                if selected1 == 1 then
                    eeprom_data.k = not eeprom_data.k
                elseif selected1 == 2 then
                    eeprom_data.e = not eeprom_data.e
                elseif selected1 == 3 then
                    eeprom_data.j = not eeprom_data.j
                elseif selected1 == 4 then
                    eeprom_data.f = not eeprom_data.f
                elseif selected1 == 4 then
                    eeprom_data.w = not eeprom_data.w
                elseif selected1 == 6 then
                    saveWithSplash()
                    break
                end
            end
            selected1 = 8
        elseif selected1 == 9 then
            break
        end
    end
end

::retryBoot::
if eeprom_data.a and eeprom_data.p and proxy(eeprom_data.a) and eeprom_data.b then
    tryUrlBoot(eeprom_data.u)
elseif eeprom_data.u ~= str_empty and internet and eeprom_data.b then
    tryBoot(eeprom_data.a, eeprom_data.p)
elseif eeprom_data.u ~= str_empty and internet then
    tryBoot(eeprom_data.a, eeprom_data.p)
elseif eeprom_data.a and eeprom_data.p and proxy(eeprom_data.a) then
    tryUrlBoot(eeprom_data.u)
end

if eeprom_data.e then
    splash"boot auto-assignments"

    empty = 1
    for fs in list"file" do
        if invoke(fs, "exists", str_initlua) then
            eeprom_data.a = fs
            eeprom_data.p = str_initlua
            empty = F
            save()
            break
        end
    end
    if eeprom_data.u == str_empty and internet and empty and eeprom_data.j then
        eeprom_data.u = str_openOSonline --openOS online
        empty = F
        save()
    end
else
    splash"no suitable boot option"
end
pullSignal(1)

goto retryBoot