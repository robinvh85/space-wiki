Vue.config.devtools = true;

var token = document.querySelector("[name='csrf-token']").content;
axios.defaults.headers.common['X-CSRF-Token'] = token;

Vue.prototype.$http = axios;

var app = new Vue({
  el: '#app',
  data: {
    currency_pairs: [],
    current_pair: '',
    bid_orders: [],
    ask_orders: []
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
    },
    get_orders: function(){
      _this = this;
      this.$http.get('/ajax/orders?pair=', {params: {pair: this.current_pair} }).then(function (res){
        _this.bid_orders = res.data['bid_orders'];
        _this.ask_orders = res.data['ask_orders'];
      });
    },
    get_currency_pairs: function(){
      _this = this;
      this.$http.get('/ajax/currency_pairs').then(function (res){
        _this.currency_pairs = res.data;
        _this.current_pair = _this.currency_pairs[0].name;
      });
    }    
  },

  created: function() {
    console.log("created");
  },
  mounted: function() {
    console.log("mounted");
    this.init();
  }
});
