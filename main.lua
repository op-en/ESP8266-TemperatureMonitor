function read_dht()
    pin = 1
    status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    if status == dht.OK then
        -- Integer firmware using this example
        -- print(string.format("DHT Temperature:%d.%03d;Humidity:%d.%03d\r\n",
        --      math.floor(temp),
        --      temp_dec,
        --      math.floor(humi),
        --      humi_dec
        --))
    
        -- Float firmware using this example
        -- print("DHT Temperature:"..temp..";".."Humidity:"..humi)
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end
end


local disp
local font

function init_display()
  local sda = 3
  local sdl = 2
  local sla = 0x3c
  i2c.setup(0,sda,sdl, i2c.SLOW)
  disp = u8g.ssd1306_128x64_i2c(sla)
  font = u8g.font_6x10
end

local function setLargeFont()
  disp:setFont(font)
  disp:setFontRefHeightExtendedText()
  disp:setDefaultForegroundColor()
  disp:setFontPosTop()
end

-- Start the draw loop with the draw implementation in the provided function callback
function updateDisplay(func)
  -- Draws one page and schedules the next page, if there is one
  local function drawPages()
    func()
    if (disp:nextPage() == true) then
      node.task.post(drawPages)
    end
  end
  -- Restart the draw loop and start drawing pages
  disp:firstPage()
  node.task.post(drawPages)
end

function drawHello()
  setLargeFont()
  disp:drawStr(30,22, "Temp:"..temp.." Hum:"..humi)
end

local drawDemo = { drawHello, drawWorld }

function demoLoop()
  -- Start the draw loop with one of the demo functions
  -- local f = table.remove(drawDemo,1) 
  -- drawHello()
  read_dht()
  updateDisplay(drawHello)
  m:publish("test/hack/temperature","Temperature:"..temp..";".."Humidity:"..humi,0,0, function(client) print("sent") end)
  -- disp:firstPage()
  -- drawHello()
  
  --table.insert(drawDemo,f)
end

-- Initialise the display
init_display()

-- Draw demo page immediately and then schedule an update every 5 seconds.
-- To test your own drawXYZ function, disable the next two lines and call updateDisplay(drawXYZ) instead.
-- demoLoop()

wifi.setmode(wifi.STATION)
wifi.sta.config("ssid", "pass")
wifi.sta.connect()
--register callback
wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("STATION_IDLE") end)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("STATION_CONNECTING") end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("STATION_WRONG_PASSWORD") end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("STATION_NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("STATION_CONNECT_FAIL") end)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function() 
    print("STATION_GOT_IP")
    --init mqtt client with keepalive timer 120sec
    m = mqtt.Client("marcusesp8266", 120, "", "")

    -- setup Last Will and Testament (optional)
    -- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
    -- to topic "/lwt" if client don't send keepalive packet
    -- m:lwt("/lwt", "offline", 0, 0)

    m:on("connect", function(client) print ("connected") end)
    m:on("offline", function(client) print ("offline") end)

    -- on publish message receive event
    m:on("message", function(client, topic, data) 
        print(topic .. ":" ) 
        if data ~= nil then
            print(data)
        end
    end)

    -- for TLS: m:connect("192.168.11.118", secure-port, 1)
    m:connect("op-en.se", 1883, 0, function(client)
        print("connected")
        --print("DHT Temperature:"..temp..";".."Humidity:"..humi)

        tmr.alarm(4, 1000, 1, demoLoop)
        
        -- m:close();
    end, 
        function(client, reason) print("failed reason: "..reason) end)

    -- Calling subscribe/publish only makes sense once the connection
    -- was successfully established. In a real-world application you want
    -- move those into the 'connect' callback or make otherwise sure the 
    -- connection was established.

    -- subscribe topic with qos = 0
    -- m:subscribe("/topic",0, function(client) print("subscribe success") end)
    -- publish a message with data = hello, QoS = 0, retain = 0
-- you can call m:connect again
end)

--register callback: use previous state
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function(previous_State)
    if(previous_State==wifi.STA_GOTIP) then 
        print("Station lost connection with access point\n\tAttempting to reconnect...")
    else
        print("STATION_CONNECTING")
    end
end)

wifi.sta.eventMonStart(100)
