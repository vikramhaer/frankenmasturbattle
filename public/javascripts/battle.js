function Choose(item) {
  new Ajax.Request('/home/battle', {
    method: 'get',
    parameters: {choice: item}
  });
  //alert("You picked " + item);
  //$.get("/home/battle", { choice: item });
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
