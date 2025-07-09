module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "lorawan"}, template("chirpstack/status"), _("LoRaWAN"), 10).leaf = true
    entry({"admin", "lorawan", "refresh_gateway_id"}, call("action_refresh_gateway_id"), nil).leaf = true
end

function get_gateway_id()
    local file = io.open("/tmp/gateway_id", "r")
    if file then
        local id = file:read("*l")
        file:close()
        return id
    end
end

function action_refresh_gateway_id()
    local cmd = "/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/get_gateway_id.sh"
    os.execute(cmd)
    luci.http.redirect(luci.dispatcher.build_url("admin", "lorawan"))
end

