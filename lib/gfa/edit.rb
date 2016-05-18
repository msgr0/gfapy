#
# Methods for the GFA class, which allow to change the content of the graph
#
module GFA::Edit

  def multiply_segment!(segment_name, copy_names)
    s = segment(segment_name)
    if copy_names.empty?
      raise ArgumentError, "multiply factor must be at least 2"
    end
    factor = 1 + copy_names.size
    divide_counts(s, factor)
    ["L","C"].each do |rt|
      [:from,:to].each do |e|
        @connect[rt][e].fetch(s,[]).each do |i|
          l = @lines[rt][i]
          # circular link counts shall be divided only ones
          next if e == :to and l.from == l.to
          divide_counts(l, factor)
        end
      end
    end
    copy_names.each do |cn|
      if @segment_names.include?(cn)
        raise ArgumentError, "Segment with name #{cn} already exists"
      end
      cpy = s.clone
      cpy.name = cn
      self << cpy
    end
    ["L","C"].each do |rt|
      [:from,:to].each do |e|
        to_clone = []
        @connect[rt][e].fetch(segment_name,[]).each {|i| to_clone << i }
        copy_names.each do |cn|
          to_clone.each do |i|
            l = @lines[rt][i].clone
            l.send(:"#{e}=", cn)
            self << l
          end
        end
      end
    end
    return self
  end

  def duplicate_segment!(segment_name, copy_name)
    multiply_segment!(segment_name, [copy_name])
  end

  # limitations:
  # - all containments und paths involving merged segments are deleted
  def merge_unbranched_segpath(first_segment, last_segment)
    segpath = unbranched_segpath(first_segment, last_segment)
    if segpath.nil?
      raise ArgumentError,
        "No unbranched segments path from #{first_segment} to #{last_segment}"
    end
    merged = segment(first_segment).clone
    merged.name = segpath.join("_")
    merged.sequence = joined_sequences(segpath)
    sum_of_counts(segpath).each do |count_tag, count|
      merged.send(:"#{count_tag}=", count)
    end
    first_reversed = (links_from(first_segment)[0].from_orient == "+")
    last_reversed = (links_to(last_segment)[0].to_orient == "+")
    self << merged
    links_to(first_segment).each do |l|
      l2 = l.clone
      l2.to = merged.name
      if first_reversed
        l2.to_orient = GFA::Line.other_orientation(l2.to_orient)
      end
      self << l2
    end
    links_from(last_segment).each do |l|
      l2 = l.clone
      l2.from = merged.name
      if last_reversed
        l2.from_orient = GFA::Line.other_orientation(l2.from_orient)
      end
      self << l2
    end
    segpath.each {|sn| delete_segment!(sn)}
    self
  end

  def unbranched_segpath(from, to)
    segpath = [from]
    last_orient = nil
    while segpath.last != to
      from_list = links_from(segpath.last)
      return nil if from_list.size != 1
      if !last_orient.nil? and from_list[0].from_orient != last_orient
        return nil
      end
      last_orient = from_list[0].to_orient
      segpath << from_list[0].to
    end
    return segpath
  end

  def delete_segment!(segment_name)
    i = @segment_names.index(segment_name)
    raise ArgumentError, "No segment has name #{segment_name}" if i.nil?
    s = @lines["S"][i]
    ["L","C"].each do |rt|
      [:from,:to].each do |e|
        @connect[rt][e].fetch(segment_name,[]).each {|li| @lines[rt][li] = nil}
        @connect[rt][e].delete(segment_name)
      end
    end
    to_rm = []
    @paths_with.fetch(segment_name,[]).each {|li| to_rm <<
                                             @lines["P"][li].path_name }
    to_rm.each {|pt| delete_path!(pt)}
    @lines["S"][i] = nil
    return self
  end

  def unconnect_segments!(from, to)
    delete_containments_or_links("C", from, nil, to, nil, nil, false)
    delete_containments_or_links("L", from, nil, to, nil, nil, false)
    delete_containments_or_links("C", to, nil, from, nil, nil, false)
    delete_containments_or_links("L", to, nil, from, nil, nil, false)
    return self
  end

  def delete_link!(from, from_orient, to, to_orient)
    delete_containments_or_links("L", from, from_orient, to,
                                 to_orient, nil, true)
  end

  def delete_containment!(from, from_orient, to, to_orient, pos)
    delete_containments_or_links("C", from, from_orient, to,
                                 to_orient, pos, true)
  end

  def delete_path!(path_name)
    i = @path_names.index(path_name)
    raise ArgumentError, "No path has name #{path_name}" if i.nil?
    pt = @lines["P"][i]
    pt.segment_name.each {|sn, o| @paths_with[sn].delete(i)}
    @lines["P"][i] = nil
    @path_names[i] = nil
    return self
  end

  private

  def divide_counts(gfa_line, factor)
    [:KC, :RC, :FC].each do |count_tag|
      if gfa_line.optional_fieldnames.include?(count_tag)
        value = (gfa_line.send(count_tag).to_f / factor)
        gfa_line.send(:"#{count_tag}=", value.to_i.to_s)
      end
    end
  end

  def sum_of_counts(segnames)
    retval = {}
    segs = segnames.map {|sn|segment(sn)}
    [:KC, :RC, :FC].each do |count_tag|
      segs.each do |s|
        if s.optional_fieldnames.include?(count_tag)
          retval[count_tag] ||= 0
          retval[count_tag] += s.send(count_tag)
        end
      end
    end
    return retval
  end

  def joined_sequences(segnames)
    retval = ""
    (segnames.size-1).times do |i|
      a = segnames[i]
      b = segnames[i+1]
      l = link!(a, nil, b, nil)
      a = segment!(a)
      b = segment!(b)
      return "*" if a.sequence == "*" or b.sequence == "*"
      if l.overlap == "*"
        cut = 0
      elsif l.overlap.size == 1 and l.overlap[0][1] == "M"
        cut = l.overlap[0][0]
      else
        raise "Overlaps contaning other operations than M are not supported"
      end
      if retval.empty?
        retval << (l.from_orient == "+" ? a.sequence : a.sequence.rc)
      end
      seq = (l.to_orient == "+" ? b.sequence : b.sequence.rc)
      if cut > 0
        raise "Inconsistent overlap" if retval[(-cut)..-1] != seq[0..(cut-1)]
      end
      retval << seq[cut..-1]
    end
    return retval
  end

  def delete_containments_or_links(rt, from, from_orient, to, to_orient, pos,
                                  firstonly = false)
    to_rm = []
    @connect[rt][:from].fetch(from,[]).each do |li|
      l = @lines[rt][li]
      if (l.to == to) and
         (to_orient.nil? or (l.to_orient == to_orient)) and
         (from_orient.nil? or (l.from_orient == from_orient)) and
         (pos.nil? or (l.pos(false) == pos.to_s))
        to_rm << li
        break if firstonly
      end
    end
    to_rm.each do |li|
      @lines[rt][li] = nil
      @connect[rt][:from].fetch(from,[]).delete(li)
      @connect[rt][:to].fetch(to,[]).delete(li)
    end
    return self
  end

end