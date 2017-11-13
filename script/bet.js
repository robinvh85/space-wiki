var DELAY_BET = 2000;
var DELAY_UI = 400;
var ratio_santo = 0.00000001;
var MAX_AMOUNT = 2048;
var START_AMOUNT = 8;
var same_amount = 0;
var previous_result_type = -2;
var current_type = 1;
var is_changed_type = false;

init();

async function start(n, type){
  current_type = type;

  for(var i=0; i<n; i++){
	is_changed_type = false;
	  
    if(i > 0){
      current_type = current_type == 0 ? 1 : 0;
    }

    var amount = START_AMOUNT;
    var step = 1;
    var current_amount = 1;
    var is_draw = false;
    var count_draw = 0;

    await sleep(100);
    while(amount <= MAX_AMOUNT){
      update_amount(amount);
      await sleep(DELAY_UI);
      
      click_bet(current_type);
      await sleep(DELAY_BET);

	  count_previous_result_type();
	  check_change_type();
	  
      if(!is_draw && is_win()){
        console.log("WIN at : " + (step));
        break;
      }

      if(amount >= MAX_AMOUNT){
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

        if(count_draw == 4){
          console.log("Out becauseof draw at step: " + step);
          break;
        }
      } 

      if(is_draw && (roll_value >= 6833 || roll_value <= 3167)){
        amount = current_amount;
        is_draw = false;
      }

      if(!is_draw && step != 4 && step != 8){
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

function getResult(){
  return $(".lottery_winner_table_second_cell")[8]
}

function getRollValue(){
  var list = $(".counter span");
  return parseInt(list[1].innerHTML + list[2].innerHTML + list[3].innerHTML + list[4].innerHTML);
}

function count_previous_result_type(){
  if(is_win()){
	if(previous_result_type == 1){	
	  same_amount++;
	} else {
	  previous_result_type = 1;
	  same_amount = 1;
	}
	return;
  }
  
  if(is_lose()){
	if(previous_result_type == 0){	
	  same_amount++;
	} else {
	  previous_result_type = 0;
	  same_amount = 1;
	}
	return;
  }
  
  if(previous_result_type == -1){
	same_amount++;
  } else {
	previous_result_type = -1;
	same_amount = 1;
  }  
}

function check_change_type(){
  if(same_amount > 3){
	current_type = current_type == 0 ? 1 : 0;
	is_changed_type = true;
  }
  
  if(is_changed_type){
	current_type = current_type == 0 ? 1 : 0;
	is_changed_type = false;
  }
}