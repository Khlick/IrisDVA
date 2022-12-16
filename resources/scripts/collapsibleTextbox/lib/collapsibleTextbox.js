// global references
var PreviousData,
  dedbox,
  label, labelContainer,
  contents, textContainer,
  rHeight,
  MaxHeight;

function buildCallback(h, fx) {
  return (...args) => fx(h, ...args);
}

// Initialize from MATLAB
function setup(htmlComponent) {
  // Store the data object
  PreviousData = htmlComponent.Data;
  MaxHeight = htmlComponent.Data.Height.max;
  
  // build callbacks
  rHeight = buildCallback(htmlComponent, reportHeight);
  // define object handles
  dedbox = document.getElementById("dedbox");
  label = document.getElementById("label-target");
  labelContainer = document.getElementById("label-container");
  contents = document.getElementById("text-target");
  textContainer = document.getElementById("text-container");
  
  // Initialize view
  let h = currentHeight();
  //  label
  label.innerHTML = htmlComponent.Data.Label;
  label.style.fontSize = htmlComponent.Data.FontSize / 12 * 0.9 + "em";
  label.style.color = htmlComponent.Data.LabelColor;
  
  // Set the open/closed status of the label
  label.classList.toggle("open", htmlComponent.Data.isOpen);
  label.classList.toggle("closed", !htmlComponent.Data.isOpen);
  dedbox.querySelectorAll('tr:not(.static)')
    .forEach((node) => node.classList.toggle("hide", !htmlComponent.Data.isOpen));  
  
    // add the click listener for the label
  label.addEventListener('click', (evt) => {
    // console.log("--- Clicked on label, processing changes...");
    let thisNode = evt.target;
    let h = currentHeight();
    ["open", "closed"].forEach((cs) => thisNode.classList.toggle(cs));
    dedbox.querySelectorAll('tr:not(.static)')
      .forEach((node) => node.classList.toggle("hide"));
    // console.log("--- Toggled shows/hides update height:");
    rHeight(h);
    // console.log("-- Heights updated from click event");
  });
  // set label background color
  labelContainer.style.backgroundColor = htmlComponent.Data.LabelBackgroundColor;
  
  // Modify the text contents
  contents.classList.toggle("mono", htmlComponent.Data.Monospaced);
  contents.style.fontSize = htmlComponent.Data.FontSize / 12 + "em";
  contents.style.color = htmlComponent.Data.TextColor;
  contents.style.maxHeight = MaxHeight - label.scrollHeight;
  contents.innerHTML = htmlComponent.Data.Text;
  // set textbox color background
  textContainer.style.backgroundColor = htmlComponent.Data.TextBackgroundColor;

  // setup data changed listener from MATLAB
  htmlComponent.addEventListener("DataChanged", (event) => {
    // console.log("--- MATLAB changed data: processing changes...");
    let newData = htmlComponent.Data;
    let previousHeight = PreviousData.Height;
    update(newData); // writes new data
    // console.log("--- now update final height (if different)");
    rHeight(previousHeight);
    // console.log("--- end of data changed event");
  });
  // report new height
  rHeight(h);
} // end setup


function currentHeight() {
  return {
    "label": label.scrollHeight,
    "contents": contents.scrollHeight,
    "max" : MaxHeight
  }
}

function totalHeight() {
  let h = currentHeight();
  return h.label + h.contents;
}

function currentStatus() {
  return label.classList.contains("open");
}

function update(newData) {
  // find keys which are different and update accordingly.
  let incomingChanges = Object.keys(newData)
    .filter(k => newData[k] !== PreviousData[k]);
  
  if (!incomingChanges.length) return

  incomingChanges.forEach((k) => {
    var h = currentHeight();
    switch (k) {
      case "Text": {
        // console.log("text edited");
        contents.innerHTML = newData.Text;
        rHeight(h);
        break;
      }
      case "Label": {
        // console.log("label edited");
        label.innerHTML = newData.Label;
        rHeight(h);
        break;
      }
      case "Monospaced": {
        // console.log("Monospaced edited");
        contents.classList.toggle("mono", newData.Monospaced);
        rHeight(h);
        break;
      }
      case "FontSize": {
        // console.log("fontsize edited");
        contents.style.fontSize = newData.FontSize / 12 + "em";
        label.style.fontSize = newData.FontSize / 12 * 0.9 + "em";
        rHeight(h);
        break;
      }
      case "TextColor": {
        // console.log("textcolor edited");
        contents.style.color = newData.TextColor;
        break;
      }
      case "TextBackgroundColor": {
        // console.log("textbgcolor edited");
        textContainer.style.backgroundColor = newData.TextBackgroundColor;
        break;
      }
      case "LabelColor": {
        // console.log("labelcolor edited");
        label.style.color = newData.LabelColor;
        break;
      }
      case "LabelBackgroundColor": {
        // console.log("labelbgcolor edited");
        labelContainer.style.backgroundColor = newData.LabelBackgroundColor;
        break;
      }
      case "Height": {
        // console.log("Height is different")
        if (MaxHeight === newData.Height.max) return
        MaxHeight = newData.Height.max;
        // console.log("MaxHeight updated.");
        rHeight(h);
        break;
      }
      case "isOpen": {
        // console.log("isopen edited");
        label.classList.toggle("open", newData.isOpen);
        label.classList.toggle("closed", !newData.isOpen);
        dedbox.querySelectorAll('tr:not(.static)')
          .forEach((node) => node.classList.toggle("hide", !newData.isOpen));
        rHeight(h);
        break;
      }
    }
  });
  //update Data
  PreviousData = newData;
}

function reportHeight(htmlComponent,oldH){
  let newStatus = currentStatus();
  let oldStatus = PreviousData.isOpen;
  
  let curHeight = currentHeight();

  if (oldH.max !== MaxHeight) {
    contents.style.maxHeight = oldH.max - curHeight.label;
    MaxHeight = oldH.max;
    curHeight = currentHeight();
  }
  
  let newHeight = totalHeight();
  let oldHeight = oldH.label + oldH.contents;
  
  if (newHeight === oldHeight && newStatus === oldStatus) {
    // console.log("heights and status the same!");
    return
  }
  // update
  let d = htmlComponent.Data;
  d.Height = curHeight;
  d.isOpen = newStatus;
  PreviousData = d;
  // trigger MATLAB
  htmlComponent.Data = d;
  // console.log("Trigger MATLAB (report height):",d)
}


//dev
// data1 = {
//   "Text": "Text",
//   "Label": "Label",
//   "Monospaced": true,
//   "FontSize": 9,
//   "TextColor": 'rgb(0,0,0)',
//   "TextBackgroundColor": 'rgba(255,255,255,1)',
//   "LabelColor": 'rgb(255,255,255)',
//   "LabelBackgroundColor": 'rgba(5,100,20,1)',
//   "Height": {"label":0,"contents":0,"max":65},
//   "isOpen": true
// };
// data2 = {
//   "Text": "Text 2",
//   "Label": "Label 2",
//   "Monospaced": true,
//   "FontSize": 12,
//   "TextColor": 'rgb(0,0,0)',
//   "TextBackgroundColor": 'rgba(255,255,255,1)',
//   "LabelColor": 'rgb(255,255,255)',
//   "LabelBackgroundColor": 'rgba(5,100,20,1)',
//   "Height": {"label":0,"contents":0,"max":85},
//   "isOpen": true
// }
// data3 = {
//   "Text": `[<span class="red">Aggregates</span>, <span class="red">Results</span>] = CurrentVoltageRamp(<span class="bold">Data</spna>, <span class="bold">GroupBy</spna>, <span class="bold">Preamble</spna>, <span class="bold">StimParam</spna>, <span class="bold">RampParams</spna>, <span class="bold">HoldParam</spna>, <span class="bold">CalciumRange</spna>, <span class="bold">gType</spna>, <span class="bold">gUnit</spna>, <span class="bold">figLabel</span>, <span class="bold">Device</spna>, <span class="bold">bgDevice</span>, <span class="bold">saveFig</spna>, <span class="bold">LedCalibrationFile</spna>, <span class="bold">LedCalibrationLabels</spna>, <span class="bold">NdCalibrationFile</spna>, <span class="bold">NdCalibrationLabels</spna>, <span class="bold">NdSources</spna>);`,
//   "Label": "Label",
//   "Monospaced": true,
//   "FontSize": 16,
//   "TextColor": 'rgb(0,0,0)',
//   "TextBackgroundColor": 'rgba(255,255,255,1)',
//   "LabelColor": 'rgb(255,255,255)',
//   "LabelBackgroundColor": 'rgba(5,100,20,1)',
//   "Height": {"label":0,"contents":0,"max":85},
//   "isOpen": false
// }
// htmlComponent = {
//   "Data": data1,
//   "addEventListener": (...args) => // console.log("EventListener called :",args)
// };