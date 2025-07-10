module("luci.controller.chirpstack", package.seeall)

function index()
    -- 放在 root 底下（= 顯示在側邊欄第一層）
    -- 排序數字設為 15，比概覽（20）略前
    entry({"admin", "chirpstack"}, template("chirpstack/status"), _("LoRaWAN"), 15).leaf = true
end
