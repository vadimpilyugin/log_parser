module Helpers
  # Top bar that displays server names and number of lines
  #
  # @param [Hash<String,Fixnum>,Hash<Symbol,Fixnum>] pages hash containing server name and number of requests OR symbol :total and Fixnum
  # @param [String] current_page name of the current page to make it active
  # @example
  # {
  #   <ul class="nav nav-tabs">
  #       <li><a href="#">All<span class="badge">1500</span></a></li>
  #       <li><a href="#">Server 1<span class="badge">1000</span></a></li>
  #       <li><a href="#">Server 2<span class="badge">500</span></a></li>
  #   </ul>                                
  # }
  # @example
  # {
  #   Hash.new(
  #     "Server 1" => 1000,
  #     "Server 2" => 500,
  #     :total => 1500
  #   )
  # }
  #
  def pagination(pages, current_page, tabs="")
    s = ""
    s << tabs+'<ul class="nav nav-tabs">' << "\n"
    s << tabs+'  '+(current_page == main_server_name ? '<li class="active">' : '<li>')
    Printer::debug(msg:"Foo bar", params:pages)
    Printer::assert(expr:pages.has_key?(:total), who:"Pagination", msg:"no :total field")
    s << tabs+'    '+href_server("", main_server_name+"&nbsp;"+badge(pages[:total]))
    s << tabs+'  </li>' << "\n"
    pages.each_pair do |server_name,value|
      if server_name.class == String
        if server_name != current_page
          s << tabs+'  <li>' << "\n"
        else
          s << tabs+'  <li class="active">' << "\n"
        end
        s << tabs+'    '+href_server(server_name, server_name + "&nbsp;" + badge(value))
        s << tabs+'  </li>' << "\n"
      end
    end
    s << tabs+'</ul>' << "\n"
    s
  end

  def badge(value)
    '<span class="badge my-align-right">' + "#{value}" + '</span>'
  end
  def href_server(server, value)
    '<a href="' + "/#{server}" << '">' + "#{value}" + '</a>'
  end
  def main_server_name
    "All"
  end

  def for_each_server(each_server_distrib, server_name,tabs='')
    @inc = 0
    recursive_hash({server_name => each_server_distrib.value[server_name]},tabs)
  end

  # @param [Hash<String,Fixnum>] hsh elements of the list. If key is not a string then it is not shown
  # @return [String] html code for a list within a panel
  def output_list_group(hsh,tabs="")
    s = "\n"
    s << tabs+'<ul class="list-group">' << "\n"
    hsh.each_pair do |key, value|
      s << tabs+'  '+'<li class="list-group-item">' << key << badge(value) << '</li>' << "\n" if key.class == String
    end
    s << tabs+'</ul>' << "\n"
    s
  end

  #
  # Returns html code of the statistics on the main page
  #
  # @param [Hash] params
  # @option params [Array] stats array containing all statistics
  # @option params [String] tabs tabulation
  def main_page_stats(params)
    s = ""
    # Show counters at the top of the page
    counters = {}
    params[:stats].each do |stat|
      if stat.class == Counter and stat.conditions.server == nil
        counters.update({stat.descr => stat.value})
        # s << output_counter(stat:stat)
      end
    end
    s << output_list_group(counters,tabs=params[:tabs])
    @inc = 0
    params[:stats].each do |stat|
      if stat.class == Distribution and stat.conditions.server == nil
        s << output_distrib_normal(stat:stat,tabs:params[:tabs],sort_type:stat.sort_type)
      end
    end
    s
  end

  #
  # Returns html code of the statistics on the server page
  #
  # @param [Hash] params
  # @option params [Array] stats array containing all statistics
  # @option params [String] server name of the server
  def server_page_stats(params)
    s = ""
    params[:stats].each do |stat|
      # Show counters at the top
      if stat.class == Counter and stat.conditions.server == params[:server]
        s << output_counter(stat:stat)
      end
    end
    # @inc = 0 Already in for_each_server
    params[:stats].each do |stat|
      if stat.class == Distribution and stat.conditions.server == params[:server]
        s << output_distrib_normal(stat:stat,tabs:params[:tabs],sort_type:stat.sort_type)
      end
    end
    s
  end

  # Returns html code for one counter
  #
  # @param [Hash] params
  # @option [Counter] stat the counter
  def output_counter(params)
    "<p>#{kv(params[:stat].descr, params[:stat].value)}</p>\n"
  end


  # Returns html for one distribution without links
  #
  # @param [Hash] params
  # @option [Distribution] stat the distribution
  # @option [String] tabs tabulation
  # @option [String] sort_type value to display
  def output_distrib_normal(params)
    recursive_hash(params[:stat].to_h, params[:tabs], params[:sort_type])
  end

  # def output_distrib(stat, tabs="")
  #   Printer::assert(expr:@distrib_num > 1 and @inc != 0, msg:"Same number for different panels!", who:"output_distrib")
  #   Printer::debug(msg:"Collapse counter: #{@inc}")
  #   Printer::debug(msg:"Distribution number: #{@distrib_num}")
  #   s = recursive_hash(stat.to_h, tabs, 0, Array.new(stat.keys.size+1))
  #   return s
  # end

  # Returns html for a nested hash with specified amount of white spaces before each line
  #
  # @param [Hash] (see Distribution#to_h)
  # @param [String] tabs white spaces before each line
  def recursive_hash(hsh,tabs="",sort_type = "total",depth=0)
    s = tabs+'<div class="panel-group">' << "\n"
    if hsh.class == Hash and hsh.values.index {|value| value.class == Hash} != nil
    	hsh.each_pair do |key,value|
    	  if value.class == Hash
          s << tabs+'  <div class="panel panel-default">' << "\n"
          s << tabs+'    <div class="panel-body">' << "\n"
          s << tabs+'      <h4 class="panel-title">' << "\n"
          if true
            # number in gray circle to the right
            s << tabs+'        <a data-toggle="collapse" href="' << "#collapse#{@inc}" << '">' << key+badge(value[sort_type.to_sym]) << '</a>' << "\n"
          else
            s << tabs+'        <a data-toggle="collapse" href="' << "#collapse#{@inc}" << '">' << kv(key,value[sort_type.to_sym]) << '</a>' << "\n"
          end
          s << tabs+'      </h4>' << "\n"
          s << tabs+'    </div>' << "\n"
          s << tabs+'    <div id="' << "collapse#{@inc}" << '" class="panel-collapse collapse">' << "\n"
          @inc += 1
          s << tabs+'      <div class="panel-body">' << "\n"
    	  	s <<               recursive_hash(value,tabs+"        ",sort_type,depth+1)
          s << tabs+'      </div>' << "\n"
          s << tabs+'    </div>' << "\n"
    	  	s << tabs+'  </div>' << "\n"
        end
      end
    elsif hsh.class == Hash and hsh.values.index {|value| value.class == Hash} == nil
      # s << tabs+'  <div class="panel panel-default">' << "\n"
      # s << tabs+'    <div class="panel-body">' << "\n"
      s << tabs+'      '+output_list_group(hsh,tabs+'      ') << "\n"
      # s << tabs+'    </div>' << "\n"
      # s << tabs+'  </div>' << "\n"
    else
      Printer::error(msg:"Trying to output #{hsh.class}, not a Hash!")
    end
    s << tabs+'</div>' << "\n"
    return s
  end
  def primitive_list_element(key,value)
    '<h4 class="panel-title">' + kv(key,value) + '</h4>'
  end
  # Outputs html code for not nested key-value hash
  #
  # @param [Hash] value the hash
  # @param [String] tabs tabulation at the start of each line
  # @return [String] the html code
  def primitive_list(value,tabs)
    s = ""
    s << tabs+'<ul>' << "\n"
    value.each_pair do |k,v|
      s << tabs+'  '+'<li>'+kv(k,v)+'</li>' << "\n" if k.class == String
    end
    s << tabs+'</ul>' << "\n"
    s
  end
  def kv(key,value)
    "#{key}: #{value}"
  end

  def big_text
  	"Anim pariatur cliche reprehenderit, enim eiusmod high 
  	life accusamus terry richardson ad squid. 3 wolf moon officia 
  	aute, non cupidatat skateboard dolor brunch. Food truck quinoa 
  	nesciunt laborum eiusmod. Brunch 3 wolf moon tempor, sunt aliqua 
  	put a bird on it squid single-origin coffee nulla assumenda shoreditch et. 
  	Nihil anim keffiyeh helvetica, craft beer labore wes anderson cred nesciunt 
  	sapiente ea proident. Ad vegan excepteur butcher vice lomo. 
  	Leggings occaecat craft beer farm-to-table, raw denim aesthetic 
  	synth nesciunt you probably haven't heard of them accusamus labore 
  	sustainable VHS"
  end
end
