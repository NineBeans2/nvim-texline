A simple statusline configuration tailored for latex writing. 

## Configuration 

- lazy.nvim

```
	{
		"NineBeans2/nvim-texline",
		dependencies = { "NineBeans2/nvim-gitbranch", "SmiteshP/nvim-navic" },
		config = function()
			require("nvim-texline").setup({ 
                    max_comp = 2,
                    togglekey = "<leader>td", -- used to toggle whether to show lsp diagnostics
                    statusline_template_full = [[%#LineNr#%branch%%<%f%m%h%r%w  %nav%%= %lav% %l,%c%V %P %-3.([%{mode(1)}]%)]],
                    })
		end,
	}
```
