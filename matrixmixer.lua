---matrix mixer for crow and norns
--
-- → 1
-- → 2
--   1 →
--   2 →
--   3 →
--   4 →
--
--
--
-- by xmacex

UI = require('ui')

local WIDTH  = 128
local HEIGHT = 64

local NINPUTS  = 2
local NOUTPUTS = 4

selected_col = 1

-- FREQ = 1/555
FREQ = 1/15

--- Init

function init()
   crow.add = init_crow

   init_crow()
   init_ui()
   init_params()
   init_param_values()
end

function init_crow()
   norns.crow.loadscript('matrixmixer.lua')
end

function init_ui()
   dials = {{}, {}}
   for row=1,NINPUTS do
      for column=1,NOUTPUTS do
	 -- local dial = UI.Dial.new(column*WIDTH/4*0.75, row*20-10, 15,
	 local dial = UI.Dial.new(-30+column*30, -30+row*30, 20,
				  0, -1, 1,
				  0, 0, {0},
				  nil, row.."→"..column)
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
	 params:add_control('amp_'..row..'_'..column, row.."→"..column, controlspec.BIPOLAR)
	 params:set_action('amp_'..row..'_'..column, function(v)
			      dials[row][column]:set_value(v)
			      redraw() -- FIXME metro instead?
			      -- FIXME why the following give me trouble? Is it because discovery is not done yet?
			      -- norns.crow.public.delta(row, selected_col, true)
			      -- norns.crow.public.delta(row, v, false)
	 end)
      end
   end
end

function init_param_values()
   -- match those in crow/matrixmixer.lua
   params:set('amp_1_1', 0.3)
   params:set('amp_2_1', 0.3)
end

--- UI/screen

function redraw()
   screen.clear()
   screen.fill()
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
   screen.update()
end

-- UI/encoders

function enc(n, d)
   if n == 1 then
      selected_col = util.wrap(selected_col+d, 1, NOUTPUTS)
      if norns.crow.public.get_count() == 2 then -- TODO more precise check that crow is ready
	 norns.crow.public.update(1, selected_col, true)
	 norns.crow.public.update(2, selected_col, true)
      end
   else
      params:delta('amp_'..(n-1)..'_'..selected_col, d)
      if norns.crow.public.get_count() == 2 then -- TODO more precise check that crow is ready
	 norns.crow.public.delta(n-1, d, false) -- FIXME this should be in the param action, not here.
      end
   end
end
