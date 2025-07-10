module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "lorawan"}, template("chirpstack/helloworld"), _("LoRaWAN"), 15).leaf = true
end
