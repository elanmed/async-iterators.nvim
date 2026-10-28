# `async-iterators.nvim`

Throttled and batched iterators built on Neovim's `vim.async` API. Iterate without freezing the UI.

## Requirements

- Neovim nightly with `vim.async` support

## `throttled_iterator()`

`throttled_iterator()` consumes an iterator in batches and yields to the main loop when the configured time threshold is reached. Call it inside a `vim.async` context; it returns after iteration completes or is cancelled.

```lua
---@class ThrottledIteratorOpts<ControlVar>
---@field threshold_ns? number Minimum time between yields, in nanoseconds. Defaults to 10 ms.
---@field should_cancel? fun(): boolean Called before each iteration; returning true stops iteration.
---@field on_iteration fun(control_var: ControlVar, ...): nil Called for every item.

--- @class ThrottledIteratorArgs<InvariantState, ControlVar>
--- @field iterator_factory fun(): ((fun(invariant_state: InvariantState, control_var: ControlVar):ControlVar), InvariantState?, ControlVar?)
--- @field threshold_ns? number
--- @field should_cancel? fun(): boolean
--- @field on_iteration fun(control_var: ControlVar, ...): nil
async_iterators.throttled_iterator(opts)
```

The iterator factory returns the iterator function, its invariant state, and its initial control variable. The iterator's first return value becomes the next control variable; iteration ends when it is `nil`.

```lua
local a = require("async_iterators")

vim.async.run(function()
  a.throttled_iterator {
    iterator_factory = function()
      return ipairs({ "one", "two", "three" })
    end,
    on_iteration = function(index, value)
      vim.print(index, value)
    end,
  }
end)
```

## `batched_iterator()`

`batched_iterator()` processes a fixed number of items before scheduling the next batch, keeping large iterations responsive. Call it inside a `vim.async` context.

```lua
---@class BatchedIteratorOpts<InvariantState, ControlVar>
---@field iterator_factory fun(): ((fun(invariant_state: InvariantState, control_var: ControlVar):ControlVar), InvariantState, ControlVar)
---@field batch_size? number Defaults to 100.
---@field should_cancel? fun(): boolean Called before each iteration; returning true stops iteration.
---@field on_iteration fun(control_var: ControlVar, ...): nil Called for every item.
---@field on_batch? fun(): nil Called after every non-empty batch.

async_iterators.batched_iterator(opts)
```

```lua
vim.async.run(function()
  a.batched_iterator {
    batch_size = 100,
    iterator_factory = function()
      return ipairs({ "one", "two", "three" })
    end,
    on_iteration = function(index, value)
      vim.print(index, value)
    end,
  }
end)
```

Cancellation is checked before each iteration, including the first one. Set `threshold_ns = 0` to yield before every iteration; the default threshold is 10 milliseconds.
