function Choose(item) {
  new Ajax.Request('/battle_update', {
    method: 'get',
    parameters: {choice: item}
  });
  //alert("You picked " + item);
  //$.get("/battle_update", { choice: item });
}

function OptionSelect(gender, network) {
  new Ajax.Request('/battle_update', {
    method: 'get',
    parameter: {gender: gender, network: network}
  });
}
      
var lastKeyPressTime = 0;
$(document).onkeydown = function(event) {
  var thisKeyPressTime = new Date();
  if (event.keyCode == 37 & thisKeyPressTime - lastKeyPressTime >= 500) {
    //Voted Face 1
    Choose("left");
    lastKeyPressTime = thisKeyPressTime;
  } 
  if(event.keyCode == 39 & thisKeyPressTime - lastKeyPressTime >= 500) {
    //Voted Face 2
    Choose("right");
    lastKeyPressTime = thisKeyPressTime;
    }      
};

document.observe("dom:loaded", function() {
  $('battle_options').observe('change', function(event) {
    $("battle_options").request({
      method: 'get',
      parameters: {option_select: true}
      });
    });
});

