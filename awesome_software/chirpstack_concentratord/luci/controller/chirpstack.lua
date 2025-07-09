-- 對應模組名稱與檔案位置：/usr/lib/lua/luci/controller/chirpstack.lua
module("luci.controller.chirpstack", package.seeall)

function index()
    -- 顯示頁面於 admin > services > chirpstack
    entry({"admin", "services", "chirpstack"}, template("chirpstack/status"), _("LoRaWAN Gateway"), 10).leaf = true

    -- 提供重新擷取 Gateway ID 的功能
    entry({"admin", "services", "chirpstack", "refresh_gateway_id"}, call("action_refresh_gateway_id"), nil).leaf = true
end

-- 重新擷取 Gateway ID 的操作
function action_refresh_gateway_id()
    local cmd = "/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/get_gateway_id.sh"
    os.execute("sh " .. cmd .. " &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "chirpstack"))
end

-- 從 /tmp/gateway_id 讀取目前 ID
function get_gateway_id()
    local file = io.open("/tmp/gateway_id", "r")
    if file then
        local id = file:read("*l")
        file:close()
        return id
    end
    return nil
end
