class BitSwitch

	def initialize(n = 0, labels = {})

		if n.is_a?(Hash)

			# Set default values
			@labels = {}
			@val = 0

			# Loop through the hash and set the switches
			i=0; n.each do |label, tf|
				self[i] = tf ? 1 : 0
				@labels[i] = label
				i += 1
			end

			# Return the BitSwitch object
			return self
		end

		# Set labels and initial number
		@labels = labels
		@val = n
	end

	# Set a bit
	def []=(bit, val)
		val = val > 0

		# If a string representation of a bit was provided get the numerical
		bit = @labels.invert[bit] if bit.is_a?(String)

		# If nil return false
		return false if bit.nil?
	
		# Set/Unset the bits
		@val |= 2 ** bit if val
		@val &= ~(2 ** bit) if !val && self[bit]

		# Return self
		return self
	end
	
	# Check a bit status
	def [](bit)

		# If a string representation of a bit was provided get the numerical
		bit = @labels.invert[bit] if bit.is_a?(String)

		# If nil return false
		return false if bit.nil?

		# Check if the bit it set
		(2 ** bit) & @val > 0
	end
	
	# Set an integer
	def set=(n)
		return false unless n.is_a?(Fixnum)
		@val = n
	end

	def labels(hash = {}, reset = false)

		# If reset is false then merge the labels
		return @labels.merge(hash) unless reset

		# Set a whole new label hash
		@labels = hash

		# Return self
		return self
	end
	
	# Convert to integer
	def to_i
		@val
	end

	# Convert to hash
	def to_hash

		# Raise an error if no labels are set
		raise StandardError, "No labels were set!" if @labels.empty?

		# Prepare new hash
		serialized = Hash.new

		# Loop through the labels
		@labels.each do |bit, label|
			serialized[label] = self[bit]
		end

		# Return the serialized BitSwitch
		serialized
	end
end

class Fixnum
	def to_switch(labels = {})
		BitSwitch.new(self, labels)
	end
end