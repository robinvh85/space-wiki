Vue.config.devtools = true;

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
  el: '#trades',
  data: {
    trading_setting_list: [],
    trading_list: [],
    traing_history_logs: [],
    selected_trade_history: null
  },
  methods: {
    init: function(){
      console.log("INIT");
      this.get_trading_setting_list();
      this.get_trading_list();
      this.call_get_history_log();

      setInterval(this.call_get_history_log, 20 * 1000);
    },
    get_trading_setting_list: function(){
      var self = this;

      this.$http.get('/ajax/trades/get_trading_list').then(function (res){
        self.trading_setting_list = res.data;
      });
    },
    get_trading_list: function(){
      var self = this;

      this.$http.get('/ajax/trades/get_trading_history_list').then(function (res){
        self.trading_list = res.data;

        for(var i=0; i< self.trading_list.length; i++){
          obj =  self.trading_list[i];
          obj.created_at = moment(obj.created_at).format("YYYY-MM-DD HH:mm:ss");
          
          if(obj.buy_at)
            obj.buy_at = moment(obj.buy_at).format("YYYY-MM-DD HH:mm:ss");
        }
      });
    },
    get_history_logs: function(trade){
      // Reset selected      
      for(var i=0; i< this.trading_list.length; i++){
        this.trading_list[i].selected = false;
      }
      trade.selected = true;
      this.selected_trade_history = trade;

      this.call_get_history_log();
    },
    cancel_trading: function(trade){
      if(confirm("Do you want to cancel this trading ?")){
        this.$http.get('/ajax/trades/cancel_trade', {params: {bot_trade_history_id: trade.id} }).then(function (res){
          if(res.data.status == 1){
            alert("Cancel successfully !")
          } else {
            alert("Can not cancel !")
          }
        });
      }
    },
    call_get_history_log: function(){
      trade_id = null;
      if(this.selected_trade_history != null){
        trade_id = this.selected_trade_history.id;
      }

      var self = this;

      this.$http.get('/ajax/trades/get_traing_history_logs', {params: {bot_trade_history_id: trade_id} }).then(function (res){
        self.traing_history_logs = res.data;

        for(var i=0; i< self.traing_history_logs.length; i++){
          obj =  self.traing_history_logs[i];
          obj.created_at = moment(obj.created_at).format("YYYY-MM-DD HH:mm:ss");
        }
      });
    }
  },
  watch: {
    // sell_value: function (value) {
    //   this.sell_percent_values = [];
    //   var percents = ['1.00', '2.00', '3.00', '5.00', '7.00', '9.00']

    //   for(var i=0; i<percents.length; i++){
    //     this.sell_percent_values.push({percent: percents[i] + '%', value: this.cal_value_percent(value, percents[i], 'increase')});
    //   }
    // },
  },
  mounted: function() {
    console.log("mounted");
    this.init();
  }
});
