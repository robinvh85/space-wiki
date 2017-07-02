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
    open_orders: [],
    balance_orders: [],
    sell_value: 0,
    buy_value: 0,
    sell_percent_values: [],
    buy_percent_values: [],
    trading: true,
    PRICE_MARK: '08',
    current_prices: {}
  },
  methods: {
    changeCurrencyPair: function(){
      console.log(this.current_pair);
      this.get_orders();
    },
    init: function(){
      console.log("INIT");
      this.get_currency_pairs();
      this.get_trading_orders();
      this.get_open_orders();
      this.get_balances();
      this.get_current_price();
      this.get_history_trade();

      setInterval(this.get_trading_orders, 60000);
      setInterval(this.get_open_orders, 60000);
      setInterval(this.get_current_price, 15000);
    },
    get_trading_orders: function(){
      _this = this;
      this.$http.get('/ajax/orders', {params: {pair: this.current_pair} }).then(function (res){
        _this.bid_orders = res.data['bid_orders'];
        _this.ask_orders = res.data['ask_orders'];

        //_this.check_trading_data();        
      });
    },
    get_current_price: function(){
      // Get all pair
      var pairs = [];
      for(var i=0; i < this.open_orders.length; i++){
        var pair = this.open_orders[i].currency_pair_name;

        if(pairs.indexOf(pair) == -1){
          pairs.push(pair);

          if(!this.current_prices[pair]){
            this.current_prices[pair] = {}
          }
        }
      }

      for(var i=0; i < this.balance_orders.length; i++){
        var pair = this.balance_orders[i].currency_pair_name;

        if(pairs.indexOf(pair) == -1){
          pairs.push(pair);
          
          if(!this.current_prices[pair]){
            this.current_prices[pair] = {}
          }
        }
      }

      for(var i=0; i<pairs.length; i++){
        var pair = pairs[i];
        this.call_get_current_price(pair);
      }      
    },
    call_get_current_price: function(pair){
      this.$http.get('/ajax/orders/get_current_price', {params: {pair: pair} }).then(function (res){
        _this.current_prices[pair].buy = res.data['buy_price'].price;
        _this.current_prices[pair].sell = res.data['sell_price'].price;

        _this.update_percent_open_order();
        _this.update_data_balance();
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
      
      return result;
    },
    price_click: function(value){
      this.sell_value = value;
      this.buy_value = value;
    },
    // Find and mark trading records
    // check_trading_data: function(){
    //   for(var i=0; i<this.bid_orders.length; i++){
    //     var reg = new RegExp(this.PRICE_MARK + '$');
    //     if(this.bid_orders[i].price.match(reg) != null){
    //       this.bid_orders[i].trading = true;
    //     }
    //   }

    //   for(var i=0; i<this.ask_orders.length; i++){
    //     var reg = new RegExp(this.PRICE_MARK + '$');
    //     if(this.ask_orders[i].price.match(reg) != null){
    //       this.ask_orders[i].trading = true;
    //     }
    //   }
    // },
    get_open_orders: function(){
      _this = this;
      this.$http.get('/ajax/orders/get_open_orders').then(function (res){
        _this.open_orders = res.data.open_orders;

        for(var i=0; i<_this.open_orders.length; i++){
          var pair = _this.open_orders[i].currency_pair_name;
          // _this.open_orders[i].date_time = moment(_this.open_orders[i].date_time).format("YYYY-MM-DD HH:mm:ss");
          _this.open_orders[i].date_time = moment(_this.open_orders[i].date_time).format("YYYY-MM-DD");                    
        }
      });
    },
    get_balances: function(){
      _this = this;
      this.$http.get('/ajax/orders/get_history_trading').then(function (res){
        _this.balance_orders = res.data;        
      });
    },
    update_data_balance: function(){
      for(var i=0; i<this.balance_orders.length; i++){
        var order = this.balance_orders[i];
        order.price = parseFloat(order.rate);

        order.current_price = parseFloat(this.current_prices[order.currency_pair_name].sell);
        order.percent_price = (this.current_prices[order.currency_pair_name].sell - order.price) / order.price * 100;

        if(order.current_price > 1000){
          order.current_price = order.current_price.toFixed(2);
          order.price = order.price.toFixed(2);
        } else if(order.current_price > 100) {
          order.current_price = order.current_price.toFixed(3);
          order.price = order.price.toFixed(3);
        } else if(order.current_price > 10){
          order.current_price = order.current_price.toFixed(5);
          order.price = order.price.toFixed(5);
        } else if(order.current_price > 1){
          order.current_price = order.current_price.toFixed(6);
          order.price = order.price.toFixed(6);
        } else {
          order.price = order.price.toFixed(8);
        }

        order.percent_price = order.percent_price.toFixed(2);        
      }
    },
    update_percent_open_order: function(){
      for(var i=0; i<this.open_orders.length; i++){
        var order = this.open_orders[i];
        order.price = parseFloat(order.price);
        if(order.order_type == 'sell'){
          order.current_price = parseFloat(this.current_prices[order.currency_pair_name].sell);          
          // order.buy_price = parseFloat(order.buy_price);

          if(order.buy_price > 0)
            order.percent_with_buy_price = ((parseFloat(order.price) - parseFloat(order.buy_price)) / parseFloat(order.buy_price) * 100).toFixed(2);
        } else if(order.order_type == 'buy') {
          order.current_price = parseFloat(this.current_prices[order.currency_pair_name].buy);
        }

        order.buy_price = parseFloat(order.buy_price);
        if(order.current_price > 1000){
          order.current_price = order.current_price.toFixed(2);
          order.buy_price = order.buy_price.toFixed(2);
          order.price = order.price.toFixed(2);
        } else if(order.current_price > 100) {
          order.current_price = order.current_price.toFixed(3);
          order.buy_price = order.buy_price.toFixed(3);
          order.price = order.price.toFixed(3);
        } else if(order.current_price > 10){
          order.current_price = order.current_price.toFixed(5);
          order.buy_price = order.buy_price.toFixed(5);
          order.price = order.price.toFixed(5);
        } else if(order.current_price > 1){
          order.current_price = order.current_price.toFixed(6);
          order.buy_price = order.buy_price.toFixed(6);
          order.price = order.price.toFixed(6);
        } else {
          order.buy_price = order.buy_price.toFixed(8);
          order.price = order.price.toFixed(8);
        }
      }      
    },
    buy_price_changed: function(item){
      this.$http.post('/ajax/orders/update_buy_price', {order_number: item.order_number, buy_price: item.buy_price}).then(function (res){
        console.log('Call: /ajax/orders/update_buy_price', res.data);
      });
    },
    cancel_order: function(item){
      if(confirm("Do you want to cancel order " + item.price + " ?")){
        this.$http.post('/ajax/orders/cancel', {order_number: item.order_number}).then(function (res){
          if(res.data.success == 1){
            alert("Cancel done !")
          }
        });
      }
    },
    done_trade: function(item){
      if(confirm("Do you want to done order " + item.price + " ?")){
        this.$http.post('/ajax/orders/done', {trade_id: item.trade_id}).then(function (res){
          if(res.data.success == 1){
            alert("Cancel done !")
          }
        });
      }
    },
    get_history_trade: function(){
      this.$http.get('/ajax/orders/get_history_trade').then(function (res){
        console.log(res.data);
      });
    }
  },
  watch: {
    sell_value: function (value) {
      this.sell_percent_values = [];
      var percents = ['0.10', '1.00', '1.50', '2.00', '3.00', '5.00']

      for(var i=0; i<percents.length; i++){
        this.sell_percent_values.push({percent: percents[i] + '%', value: this.cal_value_percent(value, percents[i], 'increase')});
      }
    },
    buy_value: function (value) {
      this.buy_percent_values = [];
      var percents = ['0.10', '0.50', '1.00', '1.50', '2.00', '3.00']

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
