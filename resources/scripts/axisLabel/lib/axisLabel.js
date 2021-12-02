// Update function
var PreviousString = String.empty;

function update(changedData) {
  let str = changedData.String;
  var txt = document.getElementById("target");
  txt.style.fontSize = changedData.FontSize + "pt";
  var previousNodes = txt.childNodes;
  MathJax.typesetClear([txt]);
  // update vertical class
  changedData.Vertical ? txt.classList.add("vertical") : txt.classList.remove("vertical");
  txt.textContent = str;
  MathJax.typesetPromise([txt]).then(() => {
    // node is typeset
  }).catch((err) => {
    // return to previous 
    MathJax.typsetClear([txt]);
    txt.replaceChildren(...previousNodes);
    console.log(err.message);
  });
}

function toggleOrientation() {
  let txt = document.getElementById("target");
  txt.classList.toggle('vertical');
}


function setup(htmlComponent) {
  // Set from initial data
  update(htmlComponent.Data);
  // add the event listener for further updates
  htmlComponent.addEventListener(
    "DataChanged",
    function (event) {
      event.preventDefault;
      update(htmlComponent.Data);
    }
  );
}

var hComp = {
  "Data": { "String": "Response", "FontSize": 14, "Vertical": false, "isValid": true },
  "addEventListener": function () { console.log("addEventListener called with: ", arguments) }
};

//