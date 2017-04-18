Vue.config.devtools = true;

showdown.setOption('tasklists', 'true');
var converter = new showdown.Converter();

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

hljs.configure({
  languages: ['javascript', 'ruby']
});

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
				_this.current_topic.modify_content = _this.current_topic.content;

				_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);	

				util.renderScriptMarkdown();
				
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
			this.current_topic.content = this.current_topic.modify_content;
			var params = {topic: this.current_topic};
			_this = this;

			this.$http.put("/topics/" + this.current_topic.id, params)
			.then(function(res){
				if(res.data.status == "OK"){										
					_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);
					_this.mode = "";

					util.renderScriptMarkdown();
				}
			})
			.catch(function(error){
				//console.log(error);
			});
		},

		show_new_topic: function() {
			this.mode = "NEW";
			this.new_topic = {
				title: '',
				content: '',
				modify_content: '',
				parent: this.current_topic
			};

			this.form = new Form(this.new_topic);
		},

		save_topic: function() {
			var _this = this;
			this.form.content = this.form.modify_content;

			this.form.post('/topics')
				.then(function(){
					_this.get_menu_list();
					_this.mode = "";

					util.renderScriptMarkdown();
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
