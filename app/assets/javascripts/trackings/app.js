Vue.config.devtools = true;

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
  el: '#trackings',
  data: {
    tracking_list: [],
  },
  methods: {
    init: function(){
      console.log("INIT");
      this.get_tracking_price_list();

      setInterval(this.get_tracking_price_list, 20 * 1000);
    },
    get_tracking_price_list: function(){
      var self = this;

      this.$http.get('/ajax/trackings/get_tracking_price_list').then(function (res){
        self.tracking_list = res.data;

        var item = null;
        for(var i=0 ;i < self.tracking_list.length; i++){
          item = self.tracking_list[i];
          item.created_at = moment(item.created_at).format("YYYY-MM-DD HH:mm:ss");

          if(Math.abs(item.changed_buy) > 2 || Math.abs(item.changed_sell) > 2 ){
            item.is_high_changed = true;
          }
        }

      });
    },
  },
  mounted: function() {
    console.log("mounted");
    this.init();
  }
});
