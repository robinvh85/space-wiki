
showdown.setOption('tasklists', 'true');
var converter = new showdown.Converter();

var token = document.querySelector("[name='csrf-token']").content
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
	el: '#app',
	data: {
		space: { children: [] },
		current_menu: {},
		current_topic: {},
		new_topic: {},
		mode: ''
	},
	methods: {
		select_menu(menu){
			this.current_menu = menu;

			let _this = this;
			this.$http.get("/topics/" + this.current_menu.id).then(function(res){
				_this.current_topic = res.data;
				_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);	
			});
		},
		edit() {
			this.mode = "EDIT";

			// Use to fix change value on simplemde
			// this.current_topic.content = this.current_topic.content.trim(); 
			this.current_topic.content += " ";
		},
		cancel() {
			this.mode = "";
		},
		update_topic() {
			let params = {topic: this.current_topic};
			_this = this;

			this.$http.put("/topics/" + this.current_topic.id, params).then(function(res){
				if(res.data.status == "OK"){					
					_this.current_topic.markdown_content = converter.makeHtml(_this.current_topic.content);
					_this.mode = "";
				}
			});
		},

		show_new_topic() {
			this.mode = "NEW";
			this.new_topic = {};
		},

		save_topic() {
			let params = {
				topic: this.new_topic,
				parent_topic: this.current_topic
			};

			let _this = this;
			this.$http.post("/topics", params).then(function(res){
				if(res.data.status == "OK"){
					_this.get_menu_list();
					_this.mode = "";
				}
			});
		},
		get_menu_list() {
			let _this = this;

			this.$http.get('/topics').then(function (res){
				_this.space = res.data;
				_this.select_menu(_this.space);
			});
		},

		change_content(content) {
			this.current_topic.content = content
		},

		change_content_new(content) {
			this.new_topic.content = content
		},		
	},

	created() {
		console.log("created");
	},
	mounted() {
		console.log("mounted");
		this.get_menu_list();
	}
});
