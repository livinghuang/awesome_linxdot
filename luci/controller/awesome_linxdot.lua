module("luci.controller.awesome_linxdot", package.seeall)

function index()
    entry({"admin", "status", "awesome_linxdot"}, call("action_message"), _("Awesome Linxdot"), 1).dependent = false
end

function action_message()
    luci.template.render("awesome_linxdot")
end
