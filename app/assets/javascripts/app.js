// Vue.http.interceptors.push({
//   request: function (request) {
//     Vue.http.headers.common['X-CSRF-Token'] = $('[name="csrf-token"]').attr('content');
//     return request;
//   },
//   response: function (response) {
//     return response;
//   }
// });

var token = document.querySelector("[name='csrf-token']").content
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
	el: '#app',
	data: {
		space: { children: [] },
		current_menu: {},
		current_topic: {},
		mode: ''
	},
	methods: {
		select_menu(menu){
			this.current_menu = menu;

			let _this = this;
			this.$http.get("/topics/" + this.current_menu.id).then(function(res){
				_this.current_topic = res.data;
			});
		},
		edit() {
			this.mode = "EDIT";
		},
		cancel() {
			this.mode = "";
		},
		update_topic() {
			let params = {topic: this.current_topic};
			this.$http.put("/topics/" + this.current_topic.id, params).then(function(res){
				if(res.data.status == "OK"){
					alert("OK");
				}
			});
		}
	},
	created() {
		console.log("created");
	},
	mounted() {
		console.log("mounted");
		let _this = this;

		this.$http.get('/topics').then(function (res){
			_this.space = res.data;
			_this.select_menu(_this.space);
		});
	}
});