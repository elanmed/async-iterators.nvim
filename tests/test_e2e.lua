local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local M = require "async"

local wait_for = function(predicate)
  eq(vim.wait(100, predicate), true)
end

local run_async = function(name, fn, opts)
  local result = {}
  local task = vim.async.run(name, function()
    result.value = fn(opts)
  end)
  task:on_complete(function(err)
    result.err = err
    result.done = true
  end)
  wait_for(function()
    return result.done == true
  end)
  return result.err or result.value
end

local T = new_set()

T["throttled_iterator()"] = new_set()

T["throttled_iterator()"]["runs in async context"] = function()
  local seen = {}
  local result = {}
  vim.async.run("runs_callback_task", function()
    result.value = M.throttled_iterator {
      iterator_factory = function()
        return function(_, n)
          if n < 3 then
            return n + 1
          end
        end,
          nil,
          0
      end,
      threshold_ns = math.huge,
      on_iteration = function(n)
        seen[#seen + 1] = n
      end,
    }
    result.done = true
  end)

  wait_for(function()
    return result.done == true
  end)
  eq(seen, { 1, 2, 3 })
  eq(result.value, nil)
end

T["throttled_iterator()"]["returns iterator factory errors"] = function()
  local err = run_async("run_async_task", M.throttled_iterator, {
    iterator_factory = function()
      error "iterator factory error"
    end,
    on_iteration = function() end,
  })
  eq(err:match "iterator factory error", "iterator factory error")
end

T["throttled_iterator()"]["returns on_iteration errors"] = function()
  local err = run_async("run_async_task", M.throttled_iterator, {
    iterator_factory = function()
      return function(_, n)
        return n + 1
      end, nil, 0
    end,
    threshold_ns = math.huge,
    on_iteration = function()
      error "on_iteration error"
    end,
  })
  eq(err:match "on_iteration error", "on_iteration error")
end

T["batched_iterator()"] = new_set()

local run_batched = function(values)
  local seen = {}
  local batches = 0
  local opts = {
    batch_size = 3,
    iterator_factory = function()
      return ipairs(values)
    end,
    on_iteration = function(_, value)
      seen[#seen + 1] = value
    end,
    on_batch = function()
      batches = batches + 1
    end,
  }
  local result = run_async("batched_iterator_task", M.batched_iterator, opts)
  eq(result, nil)
  return seen, batches
end

T["batched_iterator()"]["processes batches bigger than the batch size"] = function()
  local seen, batches = run_batched { "one", "two", "three", "four" }
  eq(seen, { "one", "two", "three", "four" })
  eq(batches, 2)
end

T["batched_iterator()"]["processes batches equal to the batch size"] = function()
  local seen, batches = run_batched { "one", "two", "three" }
  eq(seen, { "one", "two", "three" })
  eq(batches, 1)
end

T["batched_iterator()"]["processes batches smaller than the batch size"] = function()
  local seen, batches = run_batched { "one", "two" }
  eq(seen, { "one", "two" })
  eq(batches, 1)
end

T["batched_iterator()"]["cancels before the next iteration"] = function()
  local seen = {}
  local batches = 0
  local opts = {
    batch_size = 2,
    iterator_factory = function()
      return ipairs { "one", "two", "three" }
    end,
    should_cancel = function()
      return #seen >= 2
    end,
    on_iteration = function(_, value)
      seen[#seen + 1] = value
    end,
    on_batch = function()
      batches = batches + 1
    end,
  }
  run_async("batched_iterator_task", M.batched_iterator, opts)
  eq(seen, { "one", "two" })
  eq(batches, 1)
end

return T
