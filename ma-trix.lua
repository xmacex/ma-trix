--
--
--   e2      m ◉◉◉◉
--   e3      a ◉◉◉◉
--   e1       ` t r i x
--
--
-- by xmacex

UI = require('ui')
P  = norns.crow.public

local WIDTH    = 128
local HEIGHT   = 64

local NINPUTS  = 2
local NOUTPUTS = 4

local CTRLSIZE = WIDTH/NOUTPUTS
local DIALSIZE = CTRLSIZE/3*2

local dials = nil
local selected_col = 1

--- Init

function init()
   init_ui()
   init_params()
   init_param_values()

   norns.crow.add    = init_crow
   norns.crow.remove = P.reset
   init_crow()
end

function init_crow()
   P.discovered = function() bang_params_to_public() end
   norns.crow.loadscript('ma-trix.lua')
end

function init_ui()
   -- create dials
   dials = {{}, {}}
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local x = CTRLSIZE*(column-1)
	 local y = CTRLSIZE*(row-1)+3
	 local dial = UI.Dial.new(x, y, DIALSIZE,
				  0, -1, 1,
				  0, 0, {0},
				  nil, row.."→"..column)
	 if column ~= selected_col then dial.active = false end
	 table.insert(dials[row], dial)
      end
   end
end

function init_params()
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 local pid = amppid(row, column)
	 params:add_control(pid, row.."→"..column, controlspec.BIPOLAR)
	 params:set_action(pid, function(v)
			      dials[row][column]:set_value(v)
			      redraw()
			      if discovered() then
				 P.update("ch"..row, v, selected_col) -- I wish this was enough...
				 P.io['ch'..row] = P._params[row].val -- but we need to force update on remote using the low-level metamethod... or something I'm confused
			      end
	 end)
      end
   end
end

function init_param_values()
   -- match those in crow/ma-trix.lua to avoid confusion
   params:set(amppid(1, 1), 0.3)
   params:set(amppid(2, 1), 0.3)
end

function bang_params_to_public()
   -- update the status on crow to match norns params
   assert(discovered())
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
   redraw_dials()
   screen.update()
end

function redraw_dials()
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 dials[row][column]:redraw()
      end
   end
end

-- UI/encoders

function enc(n, d)
   if n == 1 then
      -- select column with e1
      selected_col = util.wrap(selected_col+d, 1, NOUTPUTS)
      -- for use wi the delta methods, which works in pair with it's third parameter. It's a bit confusing.
      -- if discovered() then
      -- 	 for column=1,NINPUTS do

      -- 	    P.delta(column, selected_col, true)
      -- 	 end
      -- end

      -- set dials of the selected column active
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
      -- adjust input with e2 and e3
      local pid = amppid(n-1, selected_col)
      params:delta(pid, d)
   end
end

--- A few utilities

function amppid(c, r)
   return "amp_"..c.."_"..r
end

function amppname(c, r)
   return "amp "..c.."→"..r
end

function discovered()
   -- assert(
   --    P.get_count() == 2 -- sadface no early return in Lua I think
   --    and P._params[1].name == "ch1"
   --    and P._params[2].name == "ch2"
   -- )
   return P.get_count() == 2
end

-- Local Variables:
-- flycheck-luacheck-standards: ("lua51" "norns")
-- End:
