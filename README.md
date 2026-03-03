A simple statusline configuration tailored for latex writing. 

## Configuration 

- lazy.nvim

```
	{
		"NineBeans2/nvim-texline",
		dependencies = { "NineBeans2/nvim-gitbranch", "SmiteshP/nvim-navic" },
		config = function()
			require("nvim-texline").setup({ max_comp = 2 })
		end,
	}
```
