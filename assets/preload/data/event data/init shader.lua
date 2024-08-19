function onEventLoaded(name, position, argument1, argument2)
    if string.lower(name) == "init shader" then
        initShader(tostring(argument1), tostring(argument2))
    end
end