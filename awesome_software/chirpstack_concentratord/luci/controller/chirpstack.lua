-- LuCI Controller - chirpstack.lua
module("luci.controller.chirpstack", package.seeall)

function index()
    -- 顯示在主選單 (root)，命名為「LoRaWAN」
    entry({"admin", "chirpstack"}, template("chirpstack/status"), _("LoRaWAN"), 30).leaf = true

    -- 按鈕動作：重新整理頁面（不執行指令）
    entry({"admin", "chirpstack", "refresh_gateway_id"}, call("action_refresh_gateway_id")).leaf = true
end

-- 讀取 /tmp/gateway_id 檔案
function get_gateway_id()
    local file = io.open("/tmp/gateway_id", "r")
    if file then
        local id = file:read("*l")
        file:close()
        return id
    end
    return nil
end

-- 「重新擷取 Gateway ID」按鈕按下後，重新載入頁面
function action_refresh_gateway_id()
    luci.http.redirect(luci.dispatcher.build_url("admin", "chirpstack"))
end
