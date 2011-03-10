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

  $('skip').observe("click", function(event) {
    $('skip').update("PUSSY");
    setTimeout("$('skip').update('Skip')",1000);
    });
});

var big_images = new Array()
var small_images = new Array()
function preload() {
  for(i = preload.arguments.length -1; i >= 0 ; i--) {
    big_images[i] = new Image();
    big_images[i].src = "http://graph.facebook.com/" + preload.arguments[i] + "/picture?type=large";
    small_images[i] = new Image();
    small_images[i].src = "http://graph.facebook.com/" + preload.arguments[i] + "/picture";
  }
}
