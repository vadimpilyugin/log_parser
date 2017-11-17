function getUrl (webhook, params) {
  s = webhook;
  s += '?';
  for (param in params) {
    if (param.length === 0) {
      return false;
    }
    s += `${param}=${encodeURIComponent(params[param])}&`;
  }
  if (s.length != 0)
    s = s.substr(0,s.length - 1);
  return s;
}

var app = new Vue ({
  el: '#app',
  data: {
    regexp: '',
    service_groups: [],
    current_service_group: '',
    categories: [],
    current_category: '',
    loglines: [],
    new_category: '',
    is_regex_wrong: false,
    button_text: 'Добавить шаблон', // текст на кнопке
    message_text: '', // текст сообщения 
    message_head: '', // заголовок
    message_classes: {
      'alert': true,
      'alert-success':true,
      'alert-danger':false,
      'alert-dismissable':true,
      'hidden':true
    },
    // константы
    DEFAULT_REGEX: '.*',
    ADD_NEW_CATEGORY: "Add new",
    IGNORE_CATEGORY: "Ignore",
  },
  watch: {
    // whenever regexp changes, this function will run
    regexp: function (new_regexp) {
      console.log(`watch: regexp(new_regexp = ${new_regexp})`);
      // не нужно, иначе проблемы со вводом
      // this.escapeAndChange ();
      this.regexp = new_regexp;
      this.loadLines ();
    },
    current_service_group: function (new_service_group) {
      console.log(`watch: regexp(new_service_group = ${new_service_group})`);
      this.current_service_group = new_service_group;
      this.regexp = '';
      this.loadCategories ();
      this.loadLines ();
    },
  },
  methods: {
    // _.debounce is a function provided by lodash to limit how
    // often a particularly expensive operation can be run.
    // In this case, we want to limit how often we access
    // yesno.wtf/api, waiting until the user has completely
    // finished typing before making the ajax request. To learn
    // more about the _.debounce function (and its cousin
    // _.throttle), visit: https://lodash.com/docs#debounce
    loadLines: _.debounce(
      function () {
        var vm = this
        var regexp = vm.regexp.length === 0 ? this.DEFAULT_REGEX : vm.regexp;
        axios.get('http://localhost:4567/loglines/no_template_found?regexp='+
          encodeURIComponent(regexp)+'&service_group='+vm.current_service_group)
          .then(function (response) {
            if (response.data["ok"] === true) {
              console.log("loadLines[data].ok", response.data);
              vm.loglines = response.data["data"];
              vm.is_regex_wrong = false;
            }
            else {
              console.log("loadLines[data].error");
              vm.is_regex_wrong = true;
            }
          })
          .catch(function (error) {
            console.log(`loadLines: could not reach the API. ${error}`);
          })
      },
      // This is the number of milliseconds we wait for the
      // user to stop typing.
      500
    ),
    escapeAndChange: function (logline) {
      var vm = this;
      var logline = encodeURIComponent (logline);
      axios.get(`http://localhost:4567/string/escape?string=${logline}`)
        .then(function (response) {
          if (response.data["ok"] === true) {
            console.log("escapeAndChange[data].ok", response.data);
            vm.regexp = response.data["data"];
          }
          else {
            console.log("escapeAndChange[data].error");
          }
          // vm.check_regexp = response.data;
        })
        .catch(function (error) {
          console.log(`escapeAndChange: could not reach the API. ${error}`);
        })
    },
    // загружает сервисы, у которых есть не подошедшие к шаблонам строки
    loadServiceGroups: function () {
      var vm = this
      axios.get(`http://localhost:4567/services/no_template_found`)
        .then(function (response) {
          if (response.data["ok"] === true) {
            console.log("loadServiceGroups[data].ok", response.data);
            vm.service_groups = response.data["data"];
          }
          else {
            console.log("loadServiceGroups[data].error");
          }
          // vm.check_regexp = response.data;
        })
        .catch(function (error) {
          console.log(`loadServiceGroups: could not reach the API. ${error}`);
        })
    },
    loadCategories: function () {
      var vm = this;
      var service_group = encodeURIComponent (this.current_service_group)
      axios.get(`http://localhost:4567/service/categories?service_group=${service_group}`)
        .then(function (response) {
          if (response.data["ok"] === true) {
            console.log("loadCategories[data].ok", response.data);
            vm.categories = response.data["data"];
            if (vm.categories.length === 0) {
              vm.categories.push(vm.IGNORE_CATEGORY);
              // vm.current_category = vm.ADD_NEW_CATEGORY;
            }
            // else {
              vm.current_category = vm.categories[0];
            // }
          }
          else {
            console.log("loadCategories[data].error");
          }
          // vm.check_regexp = response.data;
        })
        .catch(function (error) {
          console.log(`loadCategories: could not reach the API. ${error}`);
        })
    },
    getCategory: function () {
      if (this.current_category === this.ADD_NEW_CATEGORY) {
        return this.new_category;
      }
      else {
        return this.current_category;
      }
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
      setInterval(function () { vm.message_classes.hidden = true}, 5000);
    },
    postTemplate: function () {
      // ссылка на приложение
      var vm = this;
      // путь доступа к api
      var url;
      // hook
      var webhook = '/add/template';
      // проверяем параметры и конструируем url
      console.log(this.current_service_group, this.getCategory (),this.regexp)
      if (this.getCategory () === 0) {
        return false;
      }
      url = getUrl(webhook, {
        'service_group': this.current_service_group,
        'service_category': this.getCategory (),
        'regexp': this.regexp
      });
      // если параметры отсутствуют
      if (url === false) {
        console.log("Один из параметров пуст");
        return true;
      }
      // делаем запрос
      axios.post(url)
        .then(function (response) {
          if (response.data["ok"] === true) {
            // получили сервис в response.data.data
            console.log("postTemplate[data].ok", response.data.data);
            vm.displayMessage({ok:true, data:response.data.data});
            vm.loadCategories ();
            vm.loadServiceGroups ();
            vm.regexp = '';
            vm.new_category = '';
          }
          else {
            // некорректный запрос к API
            console.log(`postTemplate.err(${response.data.what}): ${response.data.descr}`);
            vm.displayMessage({ok:false, what: response.data.what, descr:response.data.descr});
          }
        })
        .catch(function (error) {
          console.log(`postTemplate: could not reach the API. ${error}`);
          vm.displayMessage({ok:false, what: "exception", descr:error});
        });
    }
  },
  created: function () {
    $.urlParam = function(name) {
      var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
      var ret = results[1] || 0;
      return decodeURIComponent(ret);
    }
    console.log($.urlParam("service_group"));
    console.log($.urlParam("logline"));
    this.current_service_group = $.urlParam("service_group");
    this.escapeAndChange ($.urlParam("logline"));
    this.loadServiceGroups ();
  }
})  

