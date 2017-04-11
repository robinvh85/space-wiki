Vue.config.devtools = true;

showdown.setOption('tasklists', 'true');
var converter = new showdown.Converter();

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

hljs.configure({
  languages: ['javascript', 'ruby']
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Errors = function () {
	function Errors() {
		_classCallCheck(this, Errors);

		this.errors = {};
	}

	_createClass(Errors, [{
		key: "get",
		value: function get(field) {
			if (this.errors[field]) {
				return this.errors[field][0];
			}
		}
		}, {
			key: "has",
			value: function has(field) {
				return this.errors.hasOwnProperty(field);
			}
		}, {
			key: "record",
			value: function record(errors) {
				this.errors = errors;
			}
		}, {
			key: "clear",
			value: function clear(field) {
				if (field) delete this.errors[field];else this.errors = {};
			}
		}, {
			key: "any",
			value: function any() {
				return Object.keys(this.errors).length > 0;
			}
		}]);

	return Errors;
}();

var Form = function () {
	function Form(data) {
		_classCallCheck(this, Form);

		this.original_data = data;

		for (var field in data) {
			this[field] = data[field];
		}

		this.errors = new Errors();
	}

	_createClass(Form, [{
		key: "data",
		value: function data() {
			// var data = Object.assign({}, this);

			// delete data.original_data;
			// delete data.errors;

			var data = {};
			for (var property in this.original_data) {
				data[property] = this[property];
			}

			return data;
		}
	}, {
		key: "reset",
		value: function reset() {
			for (var field in original_data) {
				this[field] = "";
			}

			this.errors.clear();
		}
	}, {
		key: "submit",
		value: function submit(request_type, url) {
			var _this = this;

			return new Promise(function (resolve, reject) {

				axios[request_type.toLowerCase()](url, _this.data()).then(function (response) {
					_this.onSuccess(response.data);

					resolve(response.data); // Callback on success
				}).catch(function (error) {
					_this.onFail(error.response.data.errors);

					reject(error.response.data); // Callback on fail
				});
			});
		}

		/**
  * Handle a successful form submission
  *
  * @param {object} data
  */

	}, {
		key: "onSuccess",
		value: function onSuccess(data) {
			if (data.status == "OK") {
				console.log("Save success!");
			}
		}
	}, {
		key: "onFail",
		value: function onFail(errors) {
			this.errors.record(errors);
		}
	}, {
		key: "post",
		value: function post(url) {
			return this.submit('POST', url);
		}
	}, {
		key: "delete",
		value: function _delete(url) {
			this.submit('DELETE', url);
		}
	}]);

	return Form;
}();

var app = new Vue({
	el: '#app',
	data: {
		space: { children: [] },
		current_menu: {},
		current_topic: {},
		new_topic: {},
		mode: '',
		form: new Form()
	},
	methods: {
		select_menu: function(menu){
			this.current_menu = menu;

			var _this = this;
			this.$http.get("/topics/" + this.current_menu.id).then(function(res){
				_this.current_topic = res.data;
				_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);	

				setTimeout(function(){
					document.querySelectorAll("pre code").forEach(function(item){ 
						hljs.highlightBlock(item); 
					});
				}, 50);
				
			});
		},
		edit: function() {
			this.mode = "EDIT";

			// Use to fix change value on simplemde
			// this.current_topic.content = this.current_topic.content.trim(); 
			this.current_topic.content += " ";
		},
		cancel: function() {
			this.mode = "";
		},
		update_topic: function() {
			var params = {topic: this.current_topic};
			_this = this;

			this.$http.put("/topics/" + this.current_topic.id, params).then(function(res){
				if(res.data.status == "OK"){					
					_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);
					_this.mode = "";
				}
			});
		},

		show_new_topic: function() {
			this.mode = "NEW";
			this.new_topic = {
				title: '',
				content: '',
				parent: this.current_topic
			};

			this.form = new Form(this.new_topic);
		},

		save_topic: function() {
			var _this = this;

			this.form.post('/topics')
				.then(function(){
					_this.get_menu_list();
					_this.mode = "";
				})
				.catch(function(data){
					console.log("callback error", data);
				});
		},

		get_menu_list: function() {
			var _this = this;

			this.$http.get('/topics').then(function (res){
				_this.space = res.data;
				_this.select_menu(_this.space);
			});
		},
	},

	created: function() {
		console.log("created");
	},
	mounted: function() {
		console.log("mounted");
		this.get_menu_list();
	}
});
