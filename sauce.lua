-- sauce: serialosc emulation
-- 0.0.1 @ngwese
--

--
-- globals
--

g = nil            -- connected grid
local last_path = ""     -- path of last osc msg received
local draw_clock = nil   -- clock for screen redraw
local osc_target = nil   -- where to send osc messages

prefix = ""
prefix_handlers = {}

intensity = 15

--
--  server osc handlers
--

function do_server_list(path, args, from)
  local to = args
  -- local to = {from[1], 12288}
  if g then
    osc.send(to, "/serialosc/device", {
      "m0000852",      -- serial,
      "monome 128",   -- name (g.name?),
      10111,    -- port
    })
  end
end

function do_server_notify(path, args, from)
end

function do_server_enable(path, args, from)
end

function do_server_disable(path, args, from)
end

function do_server_status(path, args, from)
  local to = args
  -- local to = {from[1], 12288}
  osc.send(to, "/serialosc/status", {1})
end

function do_server_version(path, args, from)
end

--
-- sys osc handlers
--

function do_sys_info(path, args, from)
end

function do_sys_port(path, args, from)
end

function do_sys_prefix(path, args, from)
  prefix = args[1]
  prefix_handlers = build_prefix_handlers(prefix)
end

--
-- grid osc handlers
--

function do_grid_led_set(path, args, from)
  if g then
    g:led(args[1] + 1, args[2] + 1, args[3] * intensity)
    g:refresh()
  end
end

function do_grid_led_all(path, args, from)
end

function do_grid_led_map(path, args, from)
end

function do_grid_led_row(paths, args, from)
end

function do_grid_led_col(paths, args, from)
end

function do_grid_led_intensity(paths, args, from)
end

function do_bogus(path, args, from)
  print("not implemented: " .. path)
end

server_handlers = {
  -- server
  ["/serialosc/status"] = do_server_status,
  ["/serialosc/list"] = do_server_list,
  -- sys
  ["/sys/port"] = do_sys_port,
  ["/sys/prefix"] = do_sys_prefix,
}

function build_prefix_handlers(prefix)
  return {
    -- grid
    [prefix .. "/grid/led/set"] = do_grid_led_set,
    [prefix .. "/grid/led/all"] = do_grid_led_all,
    [prefix .. "/grid/led/map"] = do_grid_led_map,
    [prefix .. "/grid/led/row"] = do_grid_led_row,
    [prefix .. "/grid/led/col"] = do_grid_led_col,
    [prefix .. "/grid/led/intensity"] = do_grid_led_intensity,
    -- arc
  }
end

function osc_in(path, args, from)
  print("path: " .. path)
  print("args:")
  tab.print(args)
  print("from:")
  tab.print(from)

  last_path = path

  local handler = prefix_handlers[path]
  if handler then
    handler(path, args, from)
    return
  end

  handler = server_handlers[path]
  if handler then
    handler(path, args, from)
    return
  end

  do_bogus(path, args, from)
end

--
-- grid callbacks
--

function grid_key(x, y, z)
  print('grid_key', x, y, z)
  if osc_target then
    print('send osc')
    osc.send(osc_target, prefix .. "/grid/key", {x, y, z})
  end
end

--
-- script callbacks
--

function redraw()
  screen.clear()
  screen.move(0, 10)
  screen.text(last_path)
  screen.update()
end

function init()
  print("sauce init")
  g = grid.connect()
  g.key = grid_key

  print("handlers:")
  tab.print(server_handlers)

  osc_target = { "caixa.local", 12288 } -- FIXME:
  osc.event = osc_in

  draw_clock = clock.run(function()
    while true do
      redraw()
      clock.sleep(1/20)
    end
  end)
end

function clean()
  print("sauce clean")
  if draw_clock then
    clock.stop(draw_clock)
  end
end
