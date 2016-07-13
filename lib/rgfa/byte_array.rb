#
# Array of positive integers <= 255;
# representation of the data contained in an H field
#
class RGFA::ByteArray < Array

  # Validates the byte array content
  # @raise [RGFA::ByteArray::ValueError] if any value is not a
  #   positive integer <= 255
  # @return [void]
  def validate!
    each do |x|
      if ![0..255].include?(x)
        raise RGFA::ByteArray::ValueError,
          "Value incompatible with byte array: #{x.inspect}\n"+
          "in array: #{self.inspect}"
      end
    end
  end

  # Returns self
  # @return [RGFA::ByteArray] self
  def to_byte_array
    self
  end

  # GFA datatype H representation of the byte array
  # @param validate [Boolean] <i>(default: +true+)</i>
  #   perform a validation of the array elements
  # @raise [RGFA::ByteArray::ValueError] if +validate+ and
  #   the array is not a valid byte array
  # @return [String]
  def to_s(validate: true)
    validate! if validate
    map{|x|x.to_s(16).upcase}.join
  end

end

# Exception raised if any value is not a positive integer <= 255
class RGFA::ByteArray::ValueError < RangeError; end

# Method to create a RGFA::ByteArray from an Array
class Array
  # Create a RGFA::ByteArray from an Array instance
  # @return [RGFA::ByteArray] the byte array
  def to_byte_array
    RGFA::ByteArray.new(self)
  end
end

# Method to parse the string representation of a RGFA::ByteArray
class String
  # Convert a GFA string representation of a byte array to a byte array
  # @return [RGFA::ByteArray] the byte array
  def to_byte_array
    scan(/..?/).map {|x|x.to_i(16)}.to_byte_array
  end
end