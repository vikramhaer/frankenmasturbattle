document.observe("dom:loaded", function() {
  new Ajax.Request('/invite_update', {
    method: 'get'
  });
});


