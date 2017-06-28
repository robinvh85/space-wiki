Vue.config.devtools = true;

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
  el: '#realtime',
  data: {
    open_orders: [],
  },
  methods: {
    init: function(){
      console.log("INIT");
      this.get_open_orders();
    },
    get_open_orders: function(){
      _this = this;
      this.$http.get('/ajax/orders/get_open_orders').then(function (res){
        _this.open_orders = res.data;

        for(var i=0; i<_this.open_orders.length; i++){
          _this.open_orders[i].date_time = moment(_this.open_orders[i].date_time).format("YYYY-MM-DD HH:mm:ss");
        }
      });
    },
  },
  mounted: function() {
    console.log("mounted");
    this.init();
  }
});
