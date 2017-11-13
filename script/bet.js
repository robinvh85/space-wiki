var DELAY_BET = 2000;
var DELAY_UI = 300;
var ratio_santo = 0.00000001;
var MAX_AMOUNT = 1024;
var START_AMOUNT = 1;
init();
 
async function start(n, type){
 
  for(var i=0; i<n; i++){
    if(i > 0){
      type = type == 0 ? 1 : 0;
    }
 
    var amount = START_AMOUNT ;
    var step = 1;
    var current_amount = 1;
    var is_draw = false;
    var count_draw = 0;
 
    await sleep(100);
    while(amount <= MAX_AMOUNT){
      update_amount(amount);
      await sleep(DELAY_UI);
 
      click_bet(type);
      await sleep(DELAY_BET);
 
      if(!is_draw && is_win()){
        console.log("WIN at : " + (step));
        break;
      }
 
      if(amount == MAX_AMOUNT){
        console.log("LOSE at : " + (step));
        await sleep(200);
        return;
      }
 
      var roll_value = getRollValue();
      if(!is_draw && roll_value < 6833 && roll_value > 3167){
        current_amount = amount;
        amount = 1;
        is_draw = true;
        count_draw++;
 
        if(count_draw == 5){
          console.log("Out becauseof draw");
          break;
        }
      } 
 
      if(is_draw && (roll_value >= 6833 || roll_value <= 3167)){
        amount = current_amount;
        is_draw = false;
      }
 
      if(!is_draw){
        amount = amount * 2;
      }
      step++;
    }
  }
}
 
function update_amount(amount){
  amount = amount * ratio_santo;
  $('#double_your_btc_stake').val(amount.toFixed(8));
}
 
function click_bet(type){
  if(type == 1){
    $('#double_your_btc_bet_hi_button').click();
  } else {
    $('#double_your_btc_bet_lo_button').click();
  }
}
 
function init(){
  $('#double_your_btc_payout_multiplier').val("3.00");
}
 
function is_lose(){
  return $('#double_your_btc_bet_lose').is(':visible');
}
 
function is_win(){
  return $('#double_your_btc_bet_win').is(':visible');
}
 
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
 
function getRndInteger(min, max) {
  return Math.floor(Math.random() * (max - min + 1) ) + min;
}
 
function getResult(){
  return $(".lottery_winner_table_second_cell")[8]
}
 
function getRollValue(){
  var list = $(".counter span");
  return parseInt(list[1].innerHTML + list[2].innerHTML + list[3].innerHTML + list[4].innerHTML);
}