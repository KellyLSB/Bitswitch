class BitSwitch
	def initialize(n = 0)
		@val = n
	end

	def []=(bit, val)
		val = val > 0
	
		@val |= 2 ** bit if val
		@val &= ~(2 ** bit) if !val && self[bit]
	end
	
	def [](bit)
		(2 ** bit) & @val > 0
	end
	
	def set=(n)
		return false unless n.is_a?(Fixnum)
		@val = n
	end
	
	def to_i
		@val
	end
end

class Fixnum
	def to_switch
		BitSwitch.new(self)
	end
end