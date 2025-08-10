---matrix mixer for crow and norns
--
-- E1 select a column
-- E2 and E2 adjust gain
--
-- It's a bipolar
-- attenuverter actually.
--
-- by xmacex

UI = require('ui')
P  = norns.crow.public

local WIDTH  = 128
local HEIGHT = 64

local NINPUTS  = 2
local NOUTPUTS = 4

local dials = nil
local selected_col = 1

--- Init

function init()
   crow.add = init_crow
   init_ui()
   init_params()
   init_param_values()

   init_crow()
end

function init_crow()
   P.discovered = function() bind_params_to_crowp() end
   norns.crow.loadscript('matrixmixer.lua')
end

function init_ui()
   dials = {{}, {}}
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local dial = UI.Dial.new(-30+column*30, -30+row*30, 20,
				  0, -1, 1,
				  0, 0, {0},
				  nil, row.."→"..column)
	 if column ~= selected_col then dial.active = false end
	 table.insert(dials[row], dial)
      end
   end
   -- FIXME why this not work? Is redraw now defined yet?
   -- ui_m = metro.init(redraw, 1/15)
   -- ui_m:start()
end

function init_params()
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local pid = amppid(row, column)
	 params:add_control(pid, row.."→"..column, controlspec.BIPOLAR)
	 params:set_action(pid, function(v)
			      dials[row][column]:set_value(v)
			      redraw() -- FIXME metro instead?
			      -- Note: crow binding is done separately
	 end)
      end
   end
end

function init_param_values()
   -- match those in crow/matrixmixer.lua
   params:set(amppid(1, 1), 0.3)
   params:set(amppid(2, 1), 0.3)
end

function bind_params_to_crowp()
   assert(P._params[1].name == "ch1")
   assert(P._params[2].name == "ch2")
   print("Discovered! binding params to crow public now")
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local pid = amppid(row, column)
	 params:set_action(pid, function(v)
			      dials[row][column]:set_value(v)
			      redraw() -- FIXME metro instead?
			      P.update("ch"..row, v, selected_col) -- I wish this was enough...
			      P.io['ch'..row] = P._params[row].val -- but we need to force update on remote using the low-level metamethod... or something I'm confused
	 end)
      end
   end
   --- TODO bang params to crow publics
   bang_params_to_public()
end

function bang_params_to_public()
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local pid = amppid(row, column)
	 print("banging "..amppname(row, column).." = "..params:get(pid))
	 P.update("ch"..row, params:get(pid), column)
	 P.io['ch'..row] = P._params[row].val -- I wish this wasn't necessary
      end
   end
end

--- UI/screen

function redraw()
   screen.clear()
   screen.fill()
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 dials[row][column]:redraw()
      end
   end
   screen.update()
end

-- UI/encoders

function enc(n, d)
   if n == 1 then
      selected_col = util.wrap(selected_col+d, 1, NOUTPUTS)
      if P.get_count() == 2 then -- TODO more precise check that crow is ready
	 for column=1,NINPUTS do
	    -- for use wi the delta methods, which works in pair
	    P.delta(column, selected_col, true)
	 end
      end
      for row=1,NINPUTS do
	 for column=1,NOUTPUTS do
	    if column == selected_col then
	       dials[row][column].active = true
	    else
	       dials[row][column].active = false
	    end
	    dials[row][column]:redraw()
	 end
      end
      redraw()
   else
      local pid = amppid(n-1, selected_col)
      params:delta(pid, d)
   end
end

function amppid(c, r)
   return "amp_"..c.."_"..r
end

function amppname(c, r)
   return "amp "..c.."→"..r
end

-- for dev convenience
function pvals(row)
   tab.print(P._params[row].val)
end
   

-- Local Variables:
-- flycheck-luacheck-standards: ("lua51" "norns")
-- End:
