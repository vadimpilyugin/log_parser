require 'uri' # URI.escape

module View

  UNDEFINED_SERVICE = 'n/a'

  def self.pagination(server_list:,active:)
    result = []
    server_list.unshift("All")
    server_list.each_with_index do |server,i|
      result << {
        name:server,
        href:(i == 0 ? '/servers/' : "/servers?server=#{server}"),
        active: (i == active)
      }
    end
    result
  end

  def table(header:, rows:)
    @header = header
    @rows = rows
    Slim::Template.new("views/table.slim").render(self)
  end

  def distr_to_html(dist_arr:)
    @cnt = 0 if @cnt.nil?
    s = ""
    # запоминаем номер группы панелей
    panel_group = @cnt
    @cnt += 1
    # для каждого распределения
    dist_arr.each do |distr|
      s << recursive_card(
        header: distr.descr,
        panel_group: "pgroup0",
        values_hsh: distr.distrib,
        top: distr.top
      )
    end
    s
  end

  def badge(value:)
    '<span class="badge badge-secondary" style="float:right">'+"#{value}"+'</span>'
  end

  def link(href:, descr:)
    '<a href='+href+'>'+descr+'</a>'
  end

  def simple_card(card_style:"", header_style:"", header_color:"", header:"",
    card_body:"", panel_group:"", count:nil, new_panel_group:nil, empty:false)

    @card_style = card_style
    @header_style = header_style
    @header_color = header_color
    @header = header
    @card_body = card_body
    @panel_group = panel_group
    @new_panel_group = new_panel_group
    @count = count
    @empty = empty
    if @cnt.nil?
      @cnt = 0
    else
      @cnt+=1
    end
    Slim::Template.new("views/card.slim").render(self)
  end
  def simple_list(list_items:)
    @list_items = list_items
    Slim::Template.new("views/list.slim").render(self)
  end

  def recursive_card(header:, values_hsh:, panel_group:, top:)
    if values_hsh.empty?
      simple_card(
        card_style:"border-light",
        header: header,
        empty:true
      )
    elsif values_hsh.values.index {|vls| vls.class == Hash}
      card_body = ""
      new_panel_group = "pgroup"+@cnt.to_s
      @cnt += 1
      row_counter = 0
      values_hsh.each_pair do |new_header, new_values_hsh|
        next if new_header.class == Symbol
        next if row_counter >= top
        card_body << recursive_card(
          header: new_header,
          values_hsh: new_values_hsh,
          panel_group: new_panel_group,
          top:top
        )
        row_counter += 1
      end
      simple_card(
        card_style:"border-light",
        header: header,
        card_body: card_body,
        panel_group: panel_group,
        new_panel_group: new_panel_group,
        count: values_hsh[:distinct]
      )
    else
      values_hsh_copy = values_hsh.clone
      values_hsh_copy.delete(:total)
      values_hsh_copy.delete(:distinct)
      values_hsh_copy.transform_values! do |val|
        simple_card(
          card_style:"border-light",
          header: 'Строки',
          card_body: simple_list(list_items:val.get_lines),
          count: val.size
        )
      end
      values_hsh_copy = values_hsh_copy.to_a[0...top]
      simple_card(
        card_style:"border-light",
        header: header,
        card_body: table(
          header:['Значение', 'Количество'],
          rows:values_hsh_copy
        ),
        panel_group: panel_group,
        count: values_hsh_copy.size
      )
    end
  end
  MAX_ERR_ROWS = 50
  def lines_to_rows(loglines)
    loglines_copy = loglines.clone
    loglines_copy.delete(:total)
    loglines_copy.delete(:distinct)
    loglines_copy.to_a.first(MAX_ERR_ROWS).map do |logline, lines|
      service = lines.first[:service] # где он есть, там будет не nil
      case lines.first[:errno]
      when Parser::FORMAT_NOT_FOUND
        [logline, UNDEFINED_SERVICE, Parser.strerror(lines.first[:errno])]
      when Parser::UNKNOWN_SERVICE
        [
          logline,
          lines.first[:service].inspect,
          link(
            href:"/service_regexp_new.html?service=#{URI.escape(service)}",
            descr:"Добавить сервис"
          )
        ]
      when Parser::TEMPLATE_NOT_FOUND
        [
          lines.first[:msg],
          lines.first[:service].inspect,
          link(
            href:"regexp.html?service_group=#{URI.escape(lines.first[:service_group])}"+\
              "&service=#{URI.escape(service)}"+\
              "&logline=#{URI.escape(logline)}",
            descr:"Добавить шаблон")
        ]
      when Parser::WRONG_FORMAT
        [logline, UNDEFINED_SERVICE, Parser.strerror(lines.first[:errno])]
      end
    end
  end
  def srv_lines_to_rows(hsh)
    hsh_clone = hsh.clone
    hsh_clone.delete(:total)
    hsh_clone.delete(:distinct)
    hsh_clone.to_a.first(MAX_ERR_ROWS).map do |service, lines|
      [
        service,
        link(
          href:"/service_regexp_new.html?service=#{URI.escape(service)}",
          descr:"Добавить сервис"
        )
      ]
    end
  end
  def unknown_services(stat:)
    simple_card(
      card_style:"mb-3",
      header_style:"text-white bg-danger",
      header_color:"color: white;",
      header: stat.descr,
      card_body: table(
        header:['Сервис', 'Описание'],
        rows:srv_lines_to_rows(stat.distrib)
      ),
      panel_group: "pgroup0",
      new_panel_group: "prgoupErrSrv"
    )
  end
  def err_card(stat:)
    card_body = ""
    stat.distrib.each_pair do |filename, lines|
      next if filename == :total || filename == :distinct
      card_body << simple_card(
        card_style:"border-light",
        header: filename,
        card_body: table(
          header:['Строка', 'Сервис', 'Описание'],
          rows:lines_to_rows(lines)
        ),
        panel_group: "prgoupErr",
        count: lines.size-2
      )
    end
    simple_card(
      card_style:"mb-3",
      header_style:"text-white bg-danger",
      header_color:"color: white;",
      header: stat.descr,
      card_body: card_body,
      panel_group: "pgroup0",
      new_panel_group: "prgoupErr"
    )
  end
end
