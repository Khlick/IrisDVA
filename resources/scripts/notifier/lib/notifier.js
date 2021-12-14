var PreviousData, container, target;
var MAX_HEIGHT = 100; // 100px default
var FONT_SCALE = 1;



function buildCallback(h, fx) {
  return (...args) => fx(h, ...args);
}

// Initialize from MATLAB
function setup(htmlComponent) {
  // populate reference variables
  container = document.getElementById("container");
  target = document.getElementById("target");

  let d = htmlComponent.Data;
  update(d)

  // setup data changed listener from MATLAB
  htmlComponent.addEventListener("DataChanged", (event) => {
    update(htmlComponent.Data);
  });

  // Listen for window resize event to scale the text
  document.body.onresize = () => {
    target.style.fontSize = (MAX_HEIGHT * FONT_SCALE + 20) + 'px';
    resizeText();
  };
  // Setupe mouseover animation for the bouncey
  target.addEventListener("mouseover", (evt) => {
    target.classList.add("bouncey");
    target.classList.remove("animated");
  });
  target.addEventListener("mouseout", (evt) => {
    target.classList.remove("bouncey");
    if (PreviousData.Animate) {
      target.classList.add("animated");
    }
  });

}

function update(d) {
  PreviousData = d;
  MAX_HEIGHT = d.TextHeight;

  // Initialize the text
  target.classList.toggle("mono", d.Monospaced);
  target.classList.remove("animated");

  FONT_SCALE = d.Monospaced ? 0.7 : 1;
  // set color scheming
  container.style.backgroundColor = d.BackgroundColor;
  target.style.color = d.TextColor;

  let str = d.Text;
  var previousNodes = target.childNodes;

  MathJax.typesetClear([target]);
  //target.textContent = str;
  target.innerHTML = str;
  target.style.fontSize = (d.TextHeight * FONT_SCALE + 20) + 'px';

  MathJax.typesetPromise([target]).then(() => {
    // node is typeset
    resizeText();
    if (d.Animate) {
      void target.offsetWidth;
      target.classList.add("animated");
    }
  }).catch((err) => {
    // return to previous 
    MathJax.typsetClear([target]);
    target.replaceChildren(...previousNodes);
  });
}

function resizeText() {
  let currentSize = window.getComputedStyle(target).fontSize;
  target.style.fontSize = (parseFloat(currentSize) - 1) + 'px';
  if (target.clientHeight >= (MAX_HEIGHT * FONT_SCALE)) {
    resizeText();
  }
}

//DEVELOPMENT DATA (Comment out for production)
var data1 = {
  "Text": "Text",
  "TextColor": "rgb(0,0,0)",
  "BackgroundColor": "rgba(100,255,155,1)",
  "TextHeight": 100,
  "Monospaced": false,
  "Animate": false
};

var data2 = {
  "Text": "$\\frac{1}{2}$",
  "TextColor": "rgb(0,0,0)",
  "BackgroundColor": "rgba(255,255,255,1)",
  "TextHeight": 100,
  "Monospaced": false,
  "Animate": false
};

var data3 = {
  "Text": "$$\\frac{1}{3}$$",
  "TextColor": "rgb(0,0,0)",
  "BackgroundColor": "rgba(255,255,255,1)",
  "TextHeight": 100,
  "Monospaced": false,
  "Animate": true
};
var data4 = {
  "Text": "Loading monospaced text with multiple lines!",
  "TextColor": "rgb(0,0,0)",
  "BackgroundColor": "rgba(255,255,255,1)",
  "TextHeight": 100,
  "Monospaced": true,
  "Animate": false
};

htmlComponent = {
  "Data": data1,
  "addEventListener": (...args) => console.log("addEventListener called :", args)
};