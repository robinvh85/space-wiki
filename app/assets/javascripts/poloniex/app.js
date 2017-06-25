Vue.config.devtools = true;

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
  el: '#poloniex',
  data: {
    currency_pairs: [],
    current_pair: '',
    bid_orders: [],
    ask_orders: [],
    sell_value: 0,
    buy_value: 0,
    sell_percent_values: [],
    buy_percent_values: [],
    trading: true,
    PRICE_MARK: '52508'
  },
  methods: {
    changeCurrencyPair: function(){
      console.log(this.current_pair);
      this.get_orders();
    },
    init: function(){
      console.log("INIT");
      this.get_currency_pairs();
      this.get_orders();

      setInterval(this.get_orders, 30000);
    },
    get_orders: function(){
      _this = this;
      this.$http.get('/ajax/orders', {params: {pair: this.current_pair} }).then(function (res){
        _this.bid_orders = res.data['bid_orders'];
        _this.ask_orders = res.data['ask_orders'];

        _this.check_trading_data();
      });
    },
    get_currency_pairs: function(){
      _this = this;
      this.$http.get('/ajax/currency_pairs').then(function (res){
        _this.currency_pairs = res.data;
        _this.current_pair = _this.currency_pairs[0].name;
      });
    },
    cal_value_percent: function(value, percent, type){
      value = parseFloat(value);
      percent = parseFloat(percent);
      var result = 0;

      if(type == "increase"){
        result = (value + (value * percent / 100)).toFixed(8);
      } else {
        result = (value - (value * percent / 100)).toFixed(8);
      }
      
      return result.toString().replace(/\d\d\d\d\d$/, this.PRICE_MARK);
    },
    price_click: function(value){
      this.sell_value = value;
      this.buy_value = value;
    },
    // buy_price_click: function(value){
    //   this.buy_value = value;
    // },
    // Find and mark trading records
    check_trading_data: function(){
      for(var i=0; i<this.bid_orders.length; i++){
        var reg = new RegExp(this.PRICE_MARK);
        if(this.bid_orders[i].price.match(reg) != null){
          this.bid_orders[i].trading = true;
        }
      }

      for(var i=0; i<this.ask_orders.length; i++){
        var reg = new RegExp(this.PRICE_MARK);
        if(this.ask_orders[i].price.match(reg) != null){
          this.ask_orders[i].trading = true;
        }
      }
    }
  },
  watch: {
    sell_value: function (value) {
      this.sell_percent_values = [];
      var percents = ['0.10', '0.75', '1.00', '1.25', '1.50', '2.00']

      for(var i=0; i<percents.length; i++){
        this.sell_percent_values.push({percent: percents[i] + '%', value: this.cal_value_percent(value, percents[i], 'increase')});
      }
    },
    buy_value: function (value) {
      this.buy_percent_values = [];
      var percents = ['0.10', '0.25', '0.50', '0.75', '1.00', '1.50']

      for(var i=0; i<percents.length; i++){
        this.buy_percent_values.push({percent: percents[i] + '%', value: this.cal_value_percent(value, percents[i], 'descrease')});
      }
    },
  },
  created: function() {
    console.log("created");
  },
  mounted: function() {
    console.log("mounted");
    this.init();
  }
});
