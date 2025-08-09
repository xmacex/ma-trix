---matrix mixer for crow
--
-- → 1
-- → 2
--   1 →
--   2 →
--   3 →
--   4 →
--
-- the action is in the public variables
--
-- by xmacex

FREQ = 1/555

public{ch1 = {0.3, 0, 0, 0}}:range(-1.0, 1.0)
public{ch2 = {0.3, 0, 0, 0}}:range(-1.0, 1.0)

function init()
   input[1].mode('none')
   input[2].mode('none')

   m = metro.init(update_outputs, FREQ):start()
end

function update_outputs()
   for i=1,4 do
      local mix = input[1].volts*public['ch1'][i] + input[2].volts*public['ch2'][i]
      output[i].volts = mix
   end
end
