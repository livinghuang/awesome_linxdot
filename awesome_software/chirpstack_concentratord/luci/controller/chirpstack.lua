module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "services", "lorawan"}, template("lorawan/status"), _("LoRaWAN Gateway"), 10).leaf = true
    entry({"admin", "services", "lorawan", "refresh_gateway_id"}, call("action_refresh_gateway_id"), nil).leaf = true
end

function action_refresh_gateway_id()
    local cmd = "/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/get_gateway_id.sh"
    os.execute("sh " .. cmd .. " &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "lorawan"))
end

function get_gateway_id()
    local file = io.open("/tmp/gateway_id", "r")
    if file then
        local id = file:read("*l")
        file:close()
        return id
    end
    return nil
end
