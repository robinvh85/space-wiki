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
  resources :poloniex

  # Trades
  get 'trades' => 'trades#index'

  # Tracking price
  get 'trakings' => 'trackings#index'

  namespace :ajax do

    post 'orders/update_buy_price' => 'orders#update_buy_price'
    post 'orders/cancel' => 'orders#cancel'
    post 'orders/done' => 'orders#done'    
    get 'orders/get_open_orders' => 'orders#get_open_orders'
    get 'orders/get_current_price' => 'orders#get_current_price'
    get 'orders/get_history_trade' => 'orders#get_history_trade'
    get 'orders/get_history_trading' => 'orders#get_history_trading'
    resources :orders

    post 'currency_pairs/update_note' => 'currency_pairs#update_note'
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
    resources :polos

    get 'trades/get_trading_list' => 'trades#get_trading_list'
    get 'trades/get_trading_history_list' => 'trades#get_trading_history_list'
    get 'trades/get_traing_history_logs' => 'trades#get_traing_history_logs'
    get 'trades/cancel_trade' => 'trades#cancel_trade'
    get 'trades/force_buy' => 'trades#force_buy'
    get 'trades/force_sell' => 'trades#force_sell'

    get 'trackings/get_tracking_price_list' => 'trackings#get_tracking_price_list'
  end

end
