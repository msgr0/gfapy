#
# Methods for the RGFA class, which allow to add lines.
#
module RGFA::LineCreators

  # Add a line to a RGFA
  #
  # @overload <<(gfa_line_string)
  #   @param [String] gfa_line_string representation of a RGFA line
  # @overload <<(gfa_line)
  #   @param [RGFA::Line] gfa_line instance of a subclass of RGFA::Line
  # @return [RGFA] self
  def <<(gfa_line)
    gfa_line = gfa_line.to_rgfa_line(validate: @validate)
    rt = gfa_line.record_type
    case rt
    when "H"
      add_header(gfa_line)
    when "S"
      add_segment(gfa_line)
    when "L", "C"
      add_link_or_containment(rt, gfa_line)
    when "P"
      add_path(gfa_line)
    else
      raise # this never happens, as already catched by gfa_line init
    end
    return self
  end

  # Sets the header data
  # @param headers_data [Hash{Symbol:Object}] data contained in the header
  #   fields; the special key :multiple_values shall contain an array of field
  #   symbols for which multiple values shall be defined in multiple lines;
  #   in this case the values must be summarized in an array
  # @return [RGFA] self
  def set_headers(headers_data)
    rm(:headers)
    multiple_values = headers_data.delete(:multiple_values)
    multiple_values ||= []
    headers_data.each do |of, values|
      values = [values] if !multiple_values.include?(of)
      if !values.kind_of?(Array)
        raise "Field #{of} listed in multiple_values key, but is not an array"
      end
      values.each do |value|
        h = "H".to_rgfa_line
        h.send(:"#{of}=", value)
        self << h
      end
    end
    return self
  end

  # Sets the value of a field in the header
  #
  # @param replace [Boolean] if true and the field already exists, the
  #   value is replaced by +value+ (regardless of +duplicate+)
  # @param duplicate [Boolean] if true and +replace+ is not set
  #   and the field already exists, the
  #   value is added, eventually creating an array of values
  #
  # @return [RGFA] self
  def set_header_field(field, value, replace: false, duplicate: false)
    # todo: summarize replace and duplicate in a single option key with three
    #       possible values
    h = headers_data
    if !h.has_key?(field) or replace
      h[field] = value
      h[:multiple_values].delete(field)
    else
      if h[:multiple_values].include?(field)
        return nil if h[field].include?(value) and !duplicate
        h[field] << value
      else
        return nil if h[field] == value and !duplicate
        h[field] = [h[field], value]
        h[:multiple_values] << field
      end
    end
    set_headers(h)
    return self
  end

  private

  def add_header(gfa_line)
    @lines["H"] << gfa_line
  end

  def add_segment(gfa_line)
    validate_segment_and_path_name_unique!(gfa_line.name) if @validate
    @segment_names[gfa_line.name.to_sym] = @lines["S"].size
    @lines["S"] << gfa_line
  end

  def add_link_or_containment(rt, gfa_line)
    if rt == "L"
      l = link(gfa_line.from_end, gfa_line.to_end)
      return if l == gfa_line
    end
    @lines[rt] << gfa_line
    [:from,:to].each do |e|
      sn = gfa_line.send(e)
      o = gfa_line.send(:"#{e}_orient")
      segment!(sn) if @segments_first_order
      @c.add(rt,@lines[rt].size-1,sn,e,o)
    end
  end

  def add_path(gfa_line)
    validate_segment_and_path_name_unique!(gfa_line.path_name) if @validate
    @path_names[gfa_line.path_name.to_sym] = @lines["P"].size
    @lines["P"] << gfa_line
    gfa_line.segment_names.each do |sn, o|
      segment!(sn) if @segments_first_order
      @c.add("P",@lines["P"].size-1,sn)
    end
  end

  def validate_segment_and_path_name_unique!(sn)
    if @segment_names.has_key?(sn.to_sym) or @path_names.has_key?(sn.to_sym)
      raise ArgumentError, "Segment or path name not unique '#{sn}'"
    end
  end

end