function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'

        dofile("main.lua")-- ***************************************************************************
    end
end

print("You have 3 seconds to abort")
print("Waiting...") 
tmr.alarm(0, 3000, 0, startup)