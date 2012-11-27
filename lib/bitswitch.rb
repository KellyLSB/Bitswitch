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
		unless reset
			@labels.merge!(hash)
			return self
		end

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

# Convert Fixnum to Switch
class Fixnum
	def to_switch(labels = {})
		BitSwitch.new(self, labels)
	end
end

# Convert hash of booleans to Switch
class Hash
	def to_switch
		cleaned = self.delete_if{|k,v| ![true, false].include?(v)}
		return BitSwitch.new if cleaned.empty?
		return BitSwitch.new(cleaned)
	end
end

# Rails 3 Extension
module KellyLSB
	module BitSwitch
		extend ActiveSupport::Concern

		module ClassMethods
			def bitswitch(column, hash = {})

				KellyLSB::BitSwitch::LocalInstanceMethods.define_method(column.to_sym) do |*args|
					val = read_attribute(column)

					# Make sure the value is an integer
					raise KellyLSB::BitSwitch::Error "Column: #{column} is not an integer!" unless val.is_a?(Fixnum)

					# Get the BitSwitch
					val = val.to_switch hash

					# Return the value of a specific key
					return val[args.first] unless args[0].nil?

					# Return the switch
					return val
				end

				columne = column.to_s + '='
				KellyLSB::BitSwitch::LocalInstanceMethods.define_method(columne.to_sym) do |*args|
					val = read_attribute(column)

					# Make sure the value is an integer
					raise KellyLSB::BitSwitch::Error "Column: #{column} is not an integer!" unless val.is_a?(Fixnum)

					# Get the BitSwitch
					val = val.to_switch hash

					# Handle the passing of a hash
					return val.to_hash.merge(args[0]).to_switch if args[0].is_a?(Hash)
					# Return the switch
					return val
				end

				KellyLSB::BitSwitch::SingletonMethods.define_method(column.to_sym) do |*args|
					raise KellyLSB::BitSwitch::Error "Missing arguments!" if args.empty?
					bits = hash.invert

					# Query
					query = self

					# Perform conditions
					args.each do |slug|
						query.where("POW(2, ?) & `#{self.table_name}`.`#{column}` > 0", bits[slug])
					end

					# Return results
					return query					
				end
				
				include KellyLSB::BitSwitch::LocalInstanceMethods
				extend KellyLSB::BitSwitch::SingletonMethods
			end
		end

		# This module contains class methods
		module SingletonMethods
		end

		module LocalInstanceMethods
		end
	end
end

puts "Active record is a class: #{ActiveRecord::Base.is_a?(Class)}"
if ActiveRecord::Base.is_a?(Class)
	ActiveRecord::Base.send(:include, KellyLSB::BitSwitch)
end