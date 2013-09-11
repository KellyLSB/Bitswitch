require 'bitswitch/version'

class BitSwitch

  def initialize(input = 0, labels = {})

    # Placeholder
    @labels = {}
    @val = 0

    # Validate the value input
    unless input.is_a?(Fixnum) || input.is_a?(Hash)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch: BitSwitch can only accept an instance of `Fixnum` or `Hash` as the first argument"
    end

    # Validate the labels input
    unless labels.is_a?(Hash)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch: BitSwitch expected the second argument to be a `Hash`"
    end

    # Validate hash value input
    if input.is_a?(Hash)
      input.each do |label, value|

        # Require a String, Symbol or Fixnum value for input hash keys
        unless label.is_a?(String) || label.is_a?(Symbol) || label.is_a?(Fixnum)
          raise KellyLSB::BitSwitch::Error,
            "BitSwitch: Input Hash keys must be a String, Symbol or Fixnum representation of the bit."
        end

        # Require input hash values to be true or false
        unless value === true || value === false
          raise KellyLSB::BitSwitch::Error,
            "BitSwitch: Input Hash values must be either true or false."
        end
      end
    end

    # Validate label hash format
    labels.each do |bit, label|

      # Require label bits to be Fixnum
      unless bit.is_a?(Fixnum)
        raise KellyLSB::BitSwitch::Error,
          "BitSwitch: Label Hash keys must be instances of Fixnum"
      end

      # Require labels to be Strings or Symbols
      unless label.is_a?(String) || label.is_a?(Symbol)
        raise KellyLSB::BitSwitch::Error,
          "BitSwitch: Label Hash values must be either Symbols or Strings"
      end
    end

    # Apply label hash into the instance variable and assume 0
    @labels = labels.inject({}){|h, (k, v)|h.merge(k => v.to_sym)}
    @val = input.is_a?(Hash) ? 0 : input

    # Handle hash input
    if input.is_a?(Hash)

      # If no labels are set
      # Loop through the input and set the values
      input.each_with_index { |(label, value), index|
        @labels[index] = label.to_sym
        self[index] = value
      } if @labels.empty?

      # Otherwise just set
      input.each { |label, value|
        self[label] = value
      } unless @labels.empty?
    end
  end

  # Set a bit (or label)
  def []=(bit, val)

    # Validate input label / bit
    unless bit.is_a?(Symbol) || bit.is_a?(String) || bit.is_a?(Fixnum)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): Expected the key to be a Symbol, String or Fixnum"
    end

    # Validate input value
    unless val === true || val === false || val.is_a?(Fixnum)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): Expected the value to be true, false or Fixnum"
    end

    # Convert numerical to boolean
    val = val > 0 if val.is_a?(Fixnum)

    # Get the numerical representation of the label
    bit = @labels.invert[bit.to_sym] unless bit.is_a?(Fixnum)

    # If nil return false
    if bit.nil?
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): There was no bit to match the requested label."
    end

    # Set/Unset the bits
    @val |= 2 ** bit if val
    @val &= ~(2 ** bit) if !val && self[bit]

    # Return self
    self
  end

  # Check a bit status
  def [](bit)

    # Validate input label / bit
    unless bit.is_a?(Symbol) || bit.is_a?(String) || bit.is_a?(Fixnum)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): Expected the key to be a Symbol, String or Fixnum"
    end

    # Get the numerical representation of the label
    bit = @labels.invert[bit.to_sym] unless bit.is_a?(Fixnum)

    # If nil return false
    if bit.nil?
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): There was no bit to match the requested label."
    end

    # Check if the bit was set
    (2 ** bit) & @val > 0
  end

  # Set an integer
  def set=(input)

    # Validate input
    unless input.is_a?(Fixnum)
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): Expected value to be a Fixnum"
    end

    # Set the value
    @val = input

    # Return self
    self
  end

  def labels(hash = {}, reset = false)

    # Either merge or overwrite labels
    @labels.merge!(hash) unless reset
    @labels = hash if reset

    # Return self
    self
  end

  # Get value
  def to_i
    @val
  end

  # Get hash
  def to_hash

    # Make sure labels are set
    if @labels.empty?
      raise KellyLSB::BitSwitch::Error,
        "BitSwitch (#{__method__}): No labels were set!"
    end

    # Prepare new hash
    serialized = Hash.new

    # Loop through the labels
    @labels.each do |bit, label|
      serialized[label] = self[bit]
    end

    # Return serialization
    serialized
  end

  # Method access
  def method_missing(method, *args)

    # Handle setting values
    if method[-1] == '='
      method = method[0..-2]
      return self[method] = args.first
    end

    # Return a value
    self[method]
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
  def to_switch(labels = {})

    # Remove any non boolean values
    cleaned = self.delete_if{|k,v| ![true, false, 1, 0, '1', '0'].include?(v)}

    # Convert Numerical Booleans
    cleaned = cleaned.inject({}) do |o,(k,v)|
      o[k] = v.is_a?(String) ? v.to_i : v
      o[k] = v.is_a?(Fixnum) ? !v.zero? : v
      o
    end

    # Return new BitSwitch
    return BitSwitch.new(0, labels) if cleaned.empty?
    return BitSwitch.new(cleaned, labels)
  end
end

# Rails 3 Extension
if defined? ActiveRecord::Base
  module KellyLSB
  module BitSwitch
    extend ActiveSupport::Concern

    module ClassMethods

      # Generate switch methods
      def bitswitch(column, hash = {})

        # Set column method name
        columne = column.to_s + '='

        # Instance methods
        send(:include, Module.new {

          # BitSwitch access method
          send(:define_method, column) do |*args|
            val = read_attribute(column)

            # If nil make 0
            val = 0 if val.nil?

            # Make sure the column value is a Fixnum
            unless val.is_a?(Fixnum)
              raise KellyLSB::BitSwitch::Error,
                "Column: #{column} is not an integer!"
            end

            # Convert the Fixnum to a BitSwitch
            val = val.to_switch hash

            # Return the value of a specific key if requested
            return val[args.first] unless args[0].nil?

            # Return the switch
            val
          end

          # BitSwitch set method
          send(:define_method, columne) do |args|
            val = read_attribute(column)

            # If nil make 0
            val = 0 if val.nil?

            # Get the input data
            if args.is_a?(Array)
              input = args[0]
              truncate = args[1]
            else
              input = args
              truncate = false
            end

            # Make sure the value is an integer
            unless val.is_a?(Fixnum)
              raise KellyLSB::BitSwitch::Error,
                "Column: #{column} is not an integer!"
            end

            # Make sure the first input is a hash
            unless input.is_a?(Hash)
              raise KellyLSB::BitSwitch::Error,
                "Input: We are expecting at least one argument that is a Hash"
            end

            # Convert Fixnum -> BitSwitch -> Hash
            val = val.to_switch(hash).to_hash

            # Convert all keys to symbols
            input.delete_if do |key, val|
              if key.is_a?(String)
                input[key.to_sym] = val
                true
              else
                false
              end
            end

            # If we are requested to truncate other keys
            if truncate == true

              # Get list of unset keys and set them to false
              remove = val.keys.collect(&:to_sym) - input.keys.collect(&:to_sym)
              remove.each { |key| input[key] = false }
            end

            # Merge in the changes then convert to BitSwitch
            val = val.merge(input).to_switch(hash)

            # Dont save if this is a new model
            return false if new_record?

            # Write the updated value
            update_column(column, val.to_i)

            # Return the switch
            return self.send(column)
          end
        })

        # Scoping methods
        send(:extend, Module.new {
          send(:define_method, column) do |*args|

            # Require at least one argument
            if args.empty?
              raise KellyLSB::BitSwitch::Error,
                "Missing arguments! We were expecing at least one label or bit to query by."
            end

            # Invert the label hash
            bits = hash.invert

            # Type of condition
            if args.first.is_a?(String) && ['AND', 'OR'].include?(args.first.to_s.upcase)
              delimiter = args.shift
            else
              delimiter = 'AND'
            end

            # Empty conditions
            conditions = Array.new

            # Build conditions
            if args.first.is_a?(Hash)
              args.first.each do |slug, tf|
                bit = bits[slug.to_s]
                conditions << "POW(2, #{bit}) & #{self.table_name}.#{column}" + (tf ? ' > 0' : ' <= 0')
              end
            else
              args.each do |slug|
                bit = bits[slug.to_s]
                conditions << "POW(2, #{bit}) & #{self.table_name}.#{column} > 0"
              end
            end

            # If we have query conditions go ahead and return the updated scope
            return self.where(conditions.join(" #{delimiter} ")) unless conditions.empty?

            # Return self
            self
          end

          send(:define_method, "#{column}_labels") do |*args|
            hash.values
          end
        })
      end
    end
  end
  end

  ActiveRecord::Base.send(:include, KellyLSB::BitSwitch)
end
