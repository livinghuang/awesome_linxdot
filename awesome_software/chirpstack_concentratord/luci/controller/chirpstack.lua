module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "chirpstack"}, template("chirpstack/status"), _("LoRaWAN"), 15).leaf = true
end
