Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'spaces#index'

  resources :spaces

  get 'search' => 'topics#search'
  get 'topics/list_topic/:id' => 'topics#list_topic'
  resources :topics

  get 'galleries/list/:topic_id'	=> 'galleries#list'
  resources :galleries

  get 'subjects/list' => 'subjects#list'  
  resources :subjects

  get 'test/list'	=> 'test#list'
  resources :test

  get 'change_subject/:id' => 'application#change_subject'
  get 'change_root_topic/:id' => 'application#change_root_topic'
  get 'default_values' => 'application#default_values'
  
  resources :current_orders
  
  get 'poloniex/chart' => 'poloniex#chart'
  get 'poloniex/compare_chart' => 'poloniex#compare_chart'
  get 'poloniex/realtime' => 'poloniex#realtime'
  get 'poloniex/analysis' => 'poloniex#analysis'
  get 'poloniex/predict' => 'poloniex#predict'
  get 'poloniex/predict_btc' => 'poloniex#predict_btc'
  get 'poloniex/predict_percent' => 'poloniex#predict_percent'
  resources :poloniex

  get 'icos' => 'icos#index'

  get 'ico1s' => 'ico1s#index'

  # Trades
  get 'trades' => 'trades#index'

  # Tracking price
  get 'trackings' => 'trackings#index'

  namespace :ajax do

    post 'orders/update_buy_price' => 'orders#update_buy_price'
    post 'orders/cancel' => 'orders#cancel'
    post 'orders/done' => 'orders#done'    
    get 'orders/get_open_orders' => 'orders#get_open_orders'
    get 'orders/get_current_price' => 'orders#get_current_price'
    get 'orders/get_history_trade' => 'orders#get_history_trade'
    get 'orders/get_history_trading' => 'orders#get_history_trading'
    get 'orders/get_open_order_btc' => 'orders#get_open_order_btc'
    post 'orders/call_sell_btc' => 'orders#call_sell_btc'
    post 'orders/call_cancel_sell_btc' => 'orders#call_cancel_sell_btc'
    post 'orders/call_buy_btc' => 'orders#call_buy_btc'
    post 'orders/call_cancel_buy_btc' => 'orders#call_cancel_buy_btc'
    get 'orders/get_bot_info' => 'orders#get_bot_info'
    put 'orders/update_bot_info' => 'orders#update_bot_info'

    resources :orders

    get 'ico_orders/get_bot_list' => 'ico_orders#get_bot_list'
    put 'ico_orders/update_bot' => 'ico_orders#update_bot'
    post 'ico_orders/cancel_sell' => 'ico_orders#cancel_sell'
    post 'ico_orders/cancel_buy' => 'ico_orders#cancel_buy'

    post 'currency_pairs/update_note' => 'currency_pairs#update_note'
    get 'currency_pairs/get_current_price' => 'currency_pairs#get_current_price'
    resources :currency_pairs

    get 'charts/get_5m' => 'charts#get_5m'
    get 'charts/get_15m' => 'charts#get_15m'
    get 'charts/get_30m' => 'charts#get_30m'
    get 'charts/get_2h' => 'charts#get_2h'
    get 'charts/get_4h' => 'charts#get_4h'
    get 'charts/get_1d' => 'charts#get_1d'
    resources :charts

    get 'chartso/get_5m' => 'chartso#get_5m'
    get 'chartso/get_15m' => 'chartso#get_15m'
    get 'chartso/get_30m' => 'chartso#get_30m'
    get 'chartso/get_2h' => 'chartso#get_2h'
    get 'chartso/get_4h' => 'chartso#get_4h'
    get 'chartso/get_1d' => 'chartso#get_1d'
    get 'chartso/get_30m_full' => 'chartso#get_30m_full'
    get 'chartso/get_5m_predict' => 'chartso#get_5m_predict'
    get 'chartso/get_5m_percent' => 'chartso#get_5m_percent'    
    resources :polos

    get 'trades/get_trading_list' => 'trades#get_trading_list'
    get 'trades/get_trading_history_list' => 'trades#get_trading_history_list'
    get 'trades/get_traing_history_logs' => 'trades#get_traing_history_logs'
    get 'trades/cancel_trade' => 'trades#cancel_trade'
    get 'trades/force_buy' => 'trades#force_buy'
    get 'trades/force_sell' => 'trades#force_sell'
    get 'trades/get_ico_list' => 'trades#get_ico_list'

    get 'trackings/get_tracking_price_list' => 'trackings#get_tracking_price_list'

    post 'bots/create' => 'bots#create'
    put 'bots/update' => 'bots#update'
  end

end
