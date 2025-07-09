module("luci.controller.chirpstack", package.seeall)

function index()
    entry({"admin", "status", "chirpstack"}, template("chirpstack/status"), _("ChirpStack Concentratord"), 90)
end
