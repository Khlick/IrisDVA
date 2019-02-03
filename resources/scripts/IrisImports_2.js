// CUSTOM LIBRARIES
// makeVisible
function makeVisible(nodeID,recurse=true) {
  dojo.setStyle(nodeID, "overflow", "visible");
  if(recurse){
    let children = nodeID.getElementsByTagName("*");
    let arr = [ ...children];
    arr.forEach( (ch) => dojo.setStyle(ch,"overflow", "visible")  );
  }
}

// Create a scriptnode and append it the dom
function makeScript(codeHTML, location="head") {
  let script = document.createElement("script");
  script.setAttribute("Type","text/javascript");
  script.innerHTML = codeHTML;
  let node = document.getElementsByTagName(location)[0];
  node.appendChild(script);
}

// callback function for keypress
function keyPressed(evnt) {
  var keyData = {};
  return  new Promise(
    (rv,rj) => {
      try {
        keyData.SOURCE = dijit.focus.activeStack[dijit.focus.activeStack.length-1] || 'root';
        keyData.CTRL = evnt.ctrlKey;
        keyData.SHIFT = evnt.shiftKey;
        keyData.ALT = evnt.altKey || evnt.metaKey;
        keyData.KEY = evnt.key;
        keyData.CHAR = evnt.char;
        keyData.CODE = evnt.code;
      } 
      catch(ee) {
        rj(ee);
      }
      rv(keyData);
    }
  );    
}
