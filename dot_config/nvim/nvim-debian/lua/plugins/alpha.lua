-- return {
--   "goolord/alpha-nvim",
--   opts = function(_, opts)
--     local logo = [[
-- 	  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- 	  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- 	  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- 	  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- 	  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- 	  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- 	                   [ Revan ]
--     ]]
--     opts.section.header.val = vim.split(logo, "\n", { trimempty = true })
--   end,
-- }
return {
	{
		"goolord/alpha-nvim",
		opts = function(_, dashboard)
			local logo = [[
		                                              
		       ████ ██████           █████      ██
		      ███████████             █████ 
		      █████████ ███████████████████ ███   ███████████
		     █████████  ███    █████████████ █████ ██████████████
		    █████████ ██████████ █████████ █████ █████ ████ █████
		  ███████████ ███    ███ █████████ █████ █████ ████ █████
		 ██████  █████████████████████ ████ █████ █████ ████ ██████

    		                          [ Revan ]

]]

dashboard.section.header.val = vim.split(logo, "\n", { trimempty = true })

-- SECTION 1: stats (dim)
dashboard.section.footer.val = function()
local stats = require("lazy").stats()
local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
return {
	("⚡ Neovim loaded %d/%d plugins in %.2fms"):format(stats.loaded, stats.count, ms),
}
end
dashboard.section.footer.opts = dashboard.section.footer.opts or {}
dashboard.section.footer.opts.position = "center"
dashboard.section.footer.opts.hl = ""

-- SECTION 2: ready line (yellow like your shortcut keys)
dashboard.section.ready = {
	type = "text",
	val = { "Ready to code!" },
	opts = { position = "center", hl = "AlphaShortcut" },
}

-- Insert the new section into the layout AFTER the footer
dashboard.config.layout = dashboard.config.layout or {}
local layout = dashboard.config.layout
local inserted = false
for i, item in ipairs(layout) do
	if item == dashboard.section.footer then
		table.insert(layout, i + 1, { type = "padding", val = 1 })
		table.insert(layout, i + 2, dashboard.section.ready)
		inserted = true
		break
		end
		end
		if not inserted then
			table.insert(layout, { type = "padding", val = 1 })
			table.insert(layout, dashboard.section.footer)
			table.insert(layout, { type = "padding", val = 1 })
			table.insert(layout, dashboard.section.ready)
			end

			return dashboard
			end,
	},
}
