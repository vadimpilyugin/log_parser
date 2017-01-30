class Output

  @indent = "\t"
  @little_ind = "  "

  def initialize(hsh = {})
    # @ostream = hsh[:ostream] ? hsh[:ostream] : $stdout
  end

  def Output.out_h(hsh)
    s = ""
    hsh.each_pair do |k, v|
      # @ostream.write(sprintf("#{@indent+@little_ind}#{k} = #{v}\n"))
      s << "#{@indent+@little_ind}#{k} = #{v}\n"
    end
    return s
  end
public
  def Output.out_entry(entry, i, layout = ["Filename", "Line No", "Data", "Meta"])
	# @ostream.write(sprintf("##{i})"))
    s = "##{i})"
    entry.each_with_index do |elem, pos|
      name = layout[pos] ? layout[pos] : "nil"
      # @ostream.write(sprintf("#{@indent}#{name}:\n"))
      s << "#{@indent}#{name}:"
      case elem.class.to_s
      when "Hash"
        # out_h elem
        s << "\n" << out_h(elem)
      else
        # @ostream.write(sprintf("#{@indent+@little_ind}#{elem}\n"))
        s << "#{@little_ind}#{elem}\n"
      end
    end
    return s
  end
  def Output.out_table(table, layout = ["Filename", "Line No", "Data", "Meta"])
    s = ""
  	table.each_with_index do |entry, i|
      s << out_entry(entry, i, layout)
    end
    # @ostream
    return s
  end
  def Output.hash_to_s(hsh)
    s = ""
    hsh.each_pair do |k,v|
      s << "#{k} = #{v}\n"
    end
    return s
  end
end
