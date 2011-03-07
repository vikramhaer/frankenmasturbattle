var lastKeyPressTime = 0
function Choose(item) {
  var thisKeyPressTime = new Date();
  if (thisKeyPressTime - lastKeyPressTime >= 1000) {
    new Ajax.Request('/battle_update', {
      method: 'get',
      parameters: {choice: item}
    });
    lastKeyPressTime = thisKeyPressTime;
  }
}
     
$(document).onkeydown = function(event) {
  if (event.keyCode == 37) {
    //Voted Face 1
    Choose("left");
  } 
  if(event.keyCode == 39) {
    //Voted Face 2
    Choose("right");
    }      
};

document.observe("dom:loaded", function() {
  $('battle_options').observe('change', function(event) {
    $("battle_options").request({
      method: 'get',
      parameters: {option_select: true}
      });
    });

  $('left').observe("click", function(event) {
    Choose("left");
    });
  $('right').observe("click", function(event) {
    Choose("right");
    });
});

