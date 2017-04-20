Vue.config.devtools = true;

showdown.setOption('tasklists', 'true');
var converter = new showdown.Converter();

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

hljs.configure({
  languages: ['javascript', 'ruby', 'css', 'html']
});

var app = new Vue({
	el: '#app',
	data: {
		space: { children: [] },
		current_menu: {},
		current_topic: {},
		new_topic: {},
		mode: '',
		form: new Form(),
		headers: [],
		is_upload: false
	},
	methods: {
		selectMenu: function(menu){
			if(this.mode == "EDIT" || this.mode == "NEW") return;

			this.current_menu = menu;

			var _this = this;
			this.$http.get("/topics/" + this.current_menu.id).then(function(res){
				_this.current_topic = res.data;
				_this.current_topic.modify_content = _this.current_topic.content;

				_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);	

				util.renderScriptMarkdown(_this.getHeaders);
				
			});
		},
		edit: function() {
			this.mode = "EDIT";

			// Use to fix change value on simplemde
			// this.current_topic.content = this.current_topic.content.trim(); 
			this.current_topic.content += " ";
			this.form = new Form(this.current_topic);
		},
		cancel: function() {
			this.mode = "";
		},
		update_topic: function() {
			this.form.content = this.form.modify_content;
			_this = this;

			this.form.put('/topics/'+ this.current_topic.id)
				.then(function(){
					_this.current_topic.markdown_content = converter.makeHtml(_this.form.content);
					_this.mode = "";
					_this.selectMenu(_this.current_menu);
				})
				.catch(function(data){
					console.log("callback error", data);
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

		save_form: function(){
			if(this.mode == "EDIT"){
				this.update_topic();
			} else {
				this.save_topic();
			}
		},

		save_topic: function() {
			var _this = this;
			this.form.content = this.form.modify_content;

			this.form.post('/topics')
				.then(function(res){
					_this.current_topic = res.topic;
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

				if(Object.keys(_this.current_topic).length > 0){
					_this.selectMenu(_this.current_topic);
				} else {
					_this.selectMenu(_this.space);
				}
			});
		},

		changeRoot: function(topic) {
			var self = this;

			this.$http.get('/topics/list_topic/' + topic.id).then(function (res){
				self.space = res.data;
				self.selectMenu(self.space);
			});
		},

		backToRoot: function(topic) {
			this.get_menu_list()
		},

		getHeaders: function() {
			this.headers = [];
			h1_list = document.getElementsByTagName("h1");
			for(var i=0; i<h1_list.length; i++){
				this.headers.push({
					id: h1_list[i].id,
					text: h1_list[i].innerText
				});
			}
		},

		scrollTo: function(header){
			var offset = document.getElementById(header.id).offsetTop
			window.scrollTo(0, offset);
		}
	},

	created: function() {
		console.log("created");
	},
	mounted: function() {
		console.log("mounted");
		this.get_menu_list();
	}
});
