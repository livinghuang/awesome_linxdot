module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "lorawan"}, template("chirpstack/status"), _("LoRaWAN"), 10)
end

function get_gateway_id()
    local file = io.open("/tmp/gateway_id", "r")
    if file then
        local id = file:read("*l")
        file:close()
        return id or "N/A"
    else
        return "N/A"
    end
end
