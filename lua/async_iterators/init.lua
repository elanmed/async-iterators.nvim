local M = {}

--- @class BatchedIteratorOpts<InvariantState, ControlVar>
--- @field iterator_factory fun(): ((fun(invariant_state: InvariantState, control_var: ControlVar):ControlVar), InvariantState, ControlVar)
--- @field batch_size? number
--- @field should_cancel? fun():boolean
--- @field on_iteration fun(entry: ControlVar):nil
--- @field on_batch? fun():nil

--- @generic InvariantState, ControlVar
--- @param opts BatchedIteratorOpts<InvariantState, ControlVar>
M.batched_iterator = function(opts)
  local batch_size = opts.batch_size or 100
  local should_cancel = opts.should_cancel or function()
    return false
  end

  local iter_fn, invariant_state, control_var = opts.iterator_factory()
  local on_batch = opts.on_batch or function() end
  while true do
    local num_processed = 0
    while num_processed < batch_size do
      if should_cancel() then
        if num_processed > 0 then
          on_batch()
        end
        return
      end

      local values = { iter_fn(invariant_state, control_var) }
      control_var = values[1]

      if control_var == nil then
        if num_processed > 0 then
          on_batch()
        end
        return
      end

      opts.on_iteration(unpack(values))
      num_processed = num_processed + 1
    end

    on_batch()
    vim.async.sleep(0)
  end
end

--- @class ThrottledIteratorOpts<InvariantState, ControlVar>
--- @field iterator_factory fun(): ((fun(invariant_state: InvariantState, control_var: ControlVar):ControlVar), InvariantState?, ControlVar?)
--- @field threshold_ns? number
--- @field should_cancel? fun():boolean
--- @field on_iteration fun(control_var: ControlVar, ...):nil

--- @generic InvariantState, ControlVar
--- @param opts ThrottledIteratorOpts<InvariantState, ControlVar>
M.throttled_iterator = function(opts)
  local threshold_ns = opts.threshold_ns or (10 * 1000000)
  local should_cancel = opts.should_cancel or function()
    return false
  end

  local last_yield = vim.uv.hrtime()
  local iter_fn, invariant_state, control_var = opts.iterator_factory()
  while true do
    if should_cancel() then
      return
    end

    local now = vim.uv.hrtime()
    if (now - last_yield) >= threshold_ns then
      last_yield = now
      vim.async.sleep(0)
    end

    local values = { iter_fn(invariant_state, control_var) }
    control_var = values[1]

    if control_var == nil then
      return
    end

    opts.on_iteration(unpack(values))
  end
end

return M
