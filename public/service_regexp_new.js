function getUrl (webhook, params) {
  s = webhook;
  s += '?';
  for (param in params) {
    s += `${param}=${encodeURIComponent(params[param])}&`;
  }
  if (s.length != 0)
    s = s.substr(0,s.length - 1);
  return s;
}

var app = new Vue ({
  el: '#app',
  data: {
    all_groups: [], // {service_group: org.gtk, regexp: 'org\.gtk\.'}
    current_group: {}, // one of all_groups
    services: [], // ошибочные сервисы, в зависимости от regex
    current_group_name: '', // связано с current_group
    current_group_regexp: '', // связано с current_group
    message_text: '', // текст сообщения 
    message_head: '', // заголовок
    message_classes: {
      'alert': true,
      'alert-success':true,
      'alert-danger':false,
      'alert-dismissable':true,
      'hidden':true
    },
    button_text: '', // текст на зеленой кнопке
    first_time: true, // заходим ли мы на секцию Add new в первый раз
    // константы
    ALL_SERVICE_GROUPS: 'all_service_groups',
    UNKNOWN_SERVICES: 'unknown_services',
    ADD_NEW: 'Add new',
    ADD_NEW_GROUP: { 
      'service_group': 'Add new',
      'regexp': ''
    },
    DEFAULT_REGEXP: '.*',
    BUTTON_ADD_NEW: 'Добавить сервис',
    BUTTON_EDIT: 'Редактировать сервис'
  },
  watch: {
    current_group: function (new_current_group) {
      this.message_classes.hidden = true;
      // если новая группа это Add new
      if (new_current_group.service_group === this.ADD_NEW) {
        if (this.first_time) {
          console.log("watcher: current_group("+new_current_group+"): first time, add new");
          this.current_group_name = $.urlParam("service");
          this.escapeAndChange (this.current_group_name);
          this.first_time = false;
        }
        else {
          console.log("watcher: current_group("+new_current_group+"): not first, add new");
          // имя группы и регулярное выражение
          this.current_group_name = '';
          this.current_group_regexp = '';
        }
        this.button_text = this.BUTTON_ADD_NEW;
      }
      else {
        console.log("watcher: current_group("+new_current_group+"): not first, not add");
        // имя группы и регулярное выражение
        this.current_group_name = this.current_group.service_group;
        this.current_group_regexp = this.current_group.regexp;
        this.button_text = this.BUTTON_EDIT;
      }
      this.current_group = new_current_group;
    },
    current_group_regexp: function (new_current_regexp) {
      console.log("watcher: current_group_regexp("+new_current_regexp+")");
      this.current_group_regexp = new_current_regexp;
      this.getServices ();
    }
  },
  methods: {
    // метод для получения списка всех групп сервисов с их шаблонами
    getAllGroups: function () {
      var vm = this;
      // путь доступа к api
      var webhook = '/services/all_service_groups';
      // параметры
      var url = getUrl(webhook, {
        'type': this.ALL_SERVICE_GROUPS
      });
      // делаем запрос
      axios.get(url)
        .then(function (response) {
          if (response.data["ok"] === true) {
            // получили нужные данные в response.data.data
            console.log("getAllGroups[data].ok", response.data.data);
            vm.all_groups = response.data.data;
            // добавляем Add new в число групп
            vm.all_groups.unshift(vm.ADD_NEW_GROUP);
            vm.current_group = vm.ADD_NEW_GROUP;
          }
          else {
            // некорректный запрос к API
            console.log(`getAllGroups.err(${response.data.what}): ${response.data.descr}`);
          }
        })
        .catch(function (error) {
          console.log(`getAllGroups: could not reach the API. ${error}`);
        });
    },
    // метод для эскейпа строки
    escapeAndChange: function (string) {
      var vm = this;
      // путь доступа к api
      var webhook = '/string/escape';
      // параметры
      var url = getUrl(webhook, {
        'string': string
      });
      // делаем запрос
      axios.get(url)
        .then(function (response) {
          if (response.data["ok"] === true) {
            // получили нужные данные в response.data.data
            console.log("escapeAndChange[data].ok", response.data.data);
            vm.current_group_regexp = response.data.data;
          }
          else {
            // некорректный запрос к API
            console.log(`escapeAndChange.err(${response.data.what}): ${response.data.descr}`);
          }
        })
        .catch(function (error) {
          console.log(`escapeAndChange: could not reach the API. ${error}`);
        });
    },
    // метод для загрузки неизвестных сервисов
    getServices: function () {
      // regexp
      var regexp = this.current_group_regexp;
      if (regexp.length === 0)
        regexp = this.DEFAULT_REGEXP;
      var vm = this;
      // путь доступа к api
      var webhook = '/services';
      // параметры
      var url = getUrl(webhook, {
        'type': this.UNKNOWN_SERVICES,
        'regexp': regexp
      });
      // делаем запрос
      axios.get(url)
        .then(function (response) {
          if (response.data["ok"] === true) {
            // получили нужные данные в response.data.data
            console.log("getServices[data].ok", response.data.data);
            vm.services = response.data.data;
          }
          else {
            // некорректный запрос к API
            console.log(`getServices.err(${response.data.what}): ${response.data.descr}`);
          }
        })
        .catch(function (error) {
          console.log(`getServices: could not reach the API. ${error}`);
        });
      },
      displayMessage: function (params) {
        if (params.ok) {
          // message success
          this.message_text = params.data;
          this.message_head = 'Success!';
          this.message_classes['alert-danger'] = false;
          this.message_classes['alert-success'] = true;
        }
        else {
          // message failure
          this.message_text = `${params.what}: ${params.descr}`;
          this.message_head = 'Error!';
          this.message_classes['alert-danger'] = true;
          this.message_classes['alert-success'] = false;
        }
        this.message_classes.hidden = false;
        vm = this;
        // setInterval(function () { vm.message_classes.hidden = true}, 5000);
      },
      postService: function () {
        // проверка параметров
        if (this.current_group_name.length === 0 
          || this.current_group_regexp.length === 0) {

          console.log("Один из параметров пуст");
          this.displayMessage({ok:false, descr:"Один из параметров пуст", what:"Некорректные параметры"});
          return true;
        }
        var vm = this;
        // путь доступа к api
        var url;
        console.log('postService: current_group.service_group == '+this.current_group.service_group);
        var new_group = this.current_group.service_group === this.ADD_NEW;
        if (new_group) {
          var webhook = '/add/service';
          url = getUrl(webhook, {
            'service_group': this.current_group_name,
            'service_regexp': this.current_group_regexp
          });
        }
        else {
          var webhook = '/update/service';
          url = getUrl(webhook, {
            'service_group':this.current_group.service_group,
            'service_regexp':this.current_group_regexp,
            'new_service_group':this.current_group_name
          });
        }
        
        // делаем запрос
        axios.post(url)
          .then(function (response) {
            if (response.data["ok"] === true) {
              // получили сервис в response.data.data
              console.log("postService[data].ok", response.data.data);
              vm.displayMessage({ok:true, data:response.data.data});
              if (!new_group) {
                vm.current_group = vm.ADD_NEW_GROUP;
              }
              vm.current_group_regexp = '';
              vm.current_group_name = '';
              vm.getAllGroups ();
              vm.getServices ();
            }
            else {
              // некорректный запрос к API
              console.log(`postService.err(${response.data.what}): ${response.data.descr}`);
              vm.displayMessage({ok:false, what: response.data.what, descr:response.data.descr});
            }
          })
          .catch(function (error) {
            console.log(`postService: could not reach the API. ${error}`);
            vm.displayMessage({ok:false, descr:error});
          });
      }
  },
  created: function () {
    // при создании берем значения из параметров
    $.urlParam = function(name) {
      var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
      var ret = results[1] || 0;
      return decodeURIComponent(ret);
    }
    // $.urlParam("service") - имя сервиса
    this.current_group = this.ADD_NEW_GROUP;
    // необходимые загрузки
    // список всех групп сервисов
    this.getAllGroups ();
    this.getServices ();
  }
})