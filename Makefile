.PHONY: dev clean test lint format docs snapshot deploy

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/async-iterators.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/async-iterators.nvim async-iterators.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

snapshot:
	mkdir -p dist
	commit=$$(git rev-parse HEAD); \
	sed "1i-- async-iterators.nvim @ $$commit" lua/async_iterators/init.lua > dist/async_iterators.lua

lint:
	# https://luals.github.io/#install
	lua-language-server --check=./lua --checklevel=Error

format:
	# https://github.com/JohnnyMorganz/StyLua#usage
	stylua .

docs:
	mkdir -p ./doc
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/async-iterators.txt async-iterators
	nvim --headless -c "helptags doc/" -c "qa"

deploy: test lint format docs snapshot
