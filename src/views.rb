module View

  def self.pagination(server_list:,active:)
    result = []
    server_list.each_with_index do |server,i|
      result << {
        name:server,
        href:(i == 0 ? '/servers/' : "/servers/#{server}"),
        active: (i == active)
      }
    end
    result
  end

  def table(header:, rows:)
    s = '
<table class="table table-hover">
  <thead><tr>'
    header.each do |elem| s << "
    <th>#{elem}</th>\n"
    end
    s << '
  </tr></thead>
  <tbody>'
    rows.each do |row|
      s << '
    <tr>'
      row.each do |elem|
        s << "
      <td>#{elem}</td>\n"
      end
      s << '
    </tr>'
    end
    s << '
  </tbody>
</table>
'
    s
  end

  def distr_to_html(dist_arr:)
    @cnt = 0 if @cnt.nil?
    # запоминаем номер группы панелей
    panel_group = @cnt
    @cnt += 1
    # записываем в s обертку группы панелей
    s = '
<div id="pgroup'+"#{panel_group}"+'">'
    # для каждого распределения
    dist_arr.each do |distr|
      # @sort_type = distr.sort_type.to_sym
      s << recursive_hash(
        panel_group: panel_group,
        descr: distr.descr,
        distr: distr.distrib,
        top: distr.top
      )
    end
    s << '
</div>'
  end

  def badge(value:)
    '<span class="badge badge-secondary" style="float:right">'+"#{value}"+'</span>'
  end

  def recursive_hash(panel_group:, descr:, distr:, top:)
    if distr.empty?
      return '
<div class="card">
  <div class="card-header">
    <h5>'+descr+' - Пусто!
    </h5>
  </div>
</div>
'
    end
    # запоминаем номер карточки
    card_no = @cnt
    # записываем в s карточку
    # if distr[@sort_type].nil?
    #   binding.irb
    # end
    s = '
<div class="card">
  <div class="card-header">
    <h5 class="mb-0">
      <a data-toggle="collapse" href="#collapse'+"#{card_no}"+'">
        '+descr+
        +badge(value:(distr[:distinct]<top ? distr[:distinct] : top))+'
      </a>
    </h5>
  </div>
  <div id="collapse'+"#{card_no}"+'" class="collapse"
  data-parent="#pgroup'+"#{panel_group}"+'">
    <div class="card-body">'
    @cnt += 1
    # в тело карточки записываем группу панелей либо таблицу
    # если в распределении присутсвуют элементы типа хэш
    if distr.values.index {|elem| elem.class == Hash }
      # присваиваем номер группе панелей
      new_panel_group = @cnt
      # записываем в s обертку вокруг группы панелей
      s << '
      <div id="pgroup'+"#{new_panel_group}"+'">'
      # для каждой пары ключ-распределение
      distr.clone.keep_if{|k,v| k.class == String }.to_a[0...top].to_h.each_pair do |key,subdist|
        # пропускаем :total и :distinct
        next if key.class == Symbol
        # увеличиваем счетчик уникальных имен
        @cnt += 1
        # в s записываем подраспределение
        s << recursive_hash(
          panel_group:new_panel_group,
          descr: key,
          distr:subdist,
          top:top
        )
      end
      # если были еще данные
      if distr[:distinct]>top
        s << '
          <div class="card">
            <div class="card-header">
              <h5> Показать еще '+"#{distr[:distinct]-top}"+'...</h5>
            </div>
          </div>
        '
      end
      # этим завершается группа панелей
      s << '
      </div>'
    else
      rows = distr.clone
      rows.delete(:total)
      rows.delete(:distinct)
      s << table(header:['Значение', 'Количество'], rows:rows.to_a[0...top])
    end
    # закрываем карточку
    s << '
    </div>
  </div>
</div>'
    return s
  end
end
