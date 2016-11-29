class Output
  def initialize(hsh = {})
    @ostream = hsh[:ostream] ? hsh[:ostream] : $stdout
    @indent = "\t"
    @little_ind = "  "
  end
public
  def out_h(hsh)
    hsh.each_pair do |k, v|
      @ostream.write(sprintf("#{@indent+@little_ind}#{k} = #{v}\n"))
    end
  end
  def out_entry(entry, i, layout = ["Filename", "Line No", "Data", "Meta"])
	@ostream.write(sprintf("##{i})"))
      entry.each_with_index do |elem, pos|
        name = layout[pos] ? layout[pos] : "nil"
        @ostream.write(sprintf("#{@indent}#{name}:\n"))
        case elem.class.to_s
        when "Hash"
          out_h elem
        else
          @ostream.write(sprintf("#{@indent+@little_ind}#{elem}\n"))
        end
      end
  end
  def out_table(table, layout = ["Filename", "Line No", "Data", "Meta"])
  	table.each_with_index do |entry, i|
      out_entry(entry, i, layout)
    end
    @ostream
  end

end
