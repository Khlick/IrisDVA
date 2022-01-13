var socket, pupil, headline, content;

// Test Data //
// const testData = { "headline": "<p class='title lab'><span class='b'>Iris</span></p><p class='lab by'><span class='i'>Data Visualization and Analysis</span></p>", "content": "<p class='lab'><span class='inc b'>Iris</span> (2022). Data Visualization and Analysis.</p><p class='lab dec'>Designed for MATLAB, Iris DVA is a tool for visualizing and analyzing electrophysiological data. <span class='b'>Version 2.0</span>, developed for the Sampath Lab, UCLA, by Khris Griffis. This software is provided as-is under the MIT License. See the <a href='https://sampathlab.gitbook.io/iris-dva' target='_system'>documentation</a> for more information.</p>" };
// htmlComponent = {
//   "Data": testData,
//   "addEventListener": (...args) => console.log("addEventListener called :", args)
// };
// END Test Data //


function setup(htmlComponent) {
  // populate references
  socket = document.getElementById("socket");
  pupil = document.getElementById("pupil");
  headline = document.getElementById("headline");
  content = document.getElementById("content");
  
  //update text
  update(htmlComponent.Data);

  // Add event listeners //

  // listen for matlab data changes
  htmlComponent.addEventListener(
    "DataChanged",
    (event) => {
      update(htmlComponent.Data)
    });

  // mouseover to trigger pupil dilation
  socket.addEventListener("mouseenter", (evt) => {
    pupil.classList.remove("dilate", "constrict");
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        pupil.classList.add("dilate");
      });
    });
  });
  socket.addEventListener("mouseleave", (evt) => {
    pupil.classList.remove("dilate", "constrict");
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        pupil.classList.add("constrict");
      });
    });
  });
}


function update(newData) {
  headline.innerHTML = newData.headline;
  content.innerHTML = newData.content;
}