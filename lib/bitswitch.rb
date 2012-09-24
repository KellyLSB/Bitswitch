class BitSwitch
	def initialize
		@val = 0
	end

	def []=(bit, val)
		val = val > 0
	
		@val |= 2 ** bit if val
		@val &= ~(2 ** bit) if !val && self[bit]
	end
	
	def [](bit)
		(2 ** bit) & @val > 0
	end
end
