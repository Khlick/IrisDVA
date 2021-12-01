function setup(htmlComponent) {
  let initialData = htmlComponent.Data;
  let dims = initialData.Dims;
  let txt = document.getElementById("target");
  txt.textContent = initialData.String;
  txt.style.fontSize = clampBuilder((dims[0] - 64)/3, (dims[0] - 64) * 3, 1, 3.5);
  
  htmlComponent.addEventListener("DataChanged", function (event) {
    event.preventDefault;
    
    let txt = document.getElementById("target");
    var changedData = htmlComponent.Data;
    let dims = changedData.Dims;
    
    // Update your HTML or JavaScript with the new data
    txt.textContent = changedData.String;
    txt.style.fontSize = clampBuilder((dims[0] - 64)/3, (dims[0] - 64) * 3, 1, 3.5);
    if (changedData.Animate) {
      txt.classList.remove("funtext");
      void txt.offsetWidth;
      txt.classList.add("funtext");
    }
    
  });
}

// Custom function for generating text resize based on window dims
// Takes the viewport widths in pixels and the font sizes in rem
function clampBuilder( minWidthPx, maxWidthPx, minFontSize, maxFontSize ) {
  const root = document.querySelector( "html" );
  const pixelsPerRem = Number( getComputedStyle( root ).fontSize.slice( 0,-2 ) );

  const minWidth = minWidthPx / pixelsPerRem;
  const maxWidth = maxWidthPx / pixelsPerRem;

  const slope = ( maxFontSize - minFontSize ) / ( maxWidth - minWidth );
  const yAxisIntersection = -minWidth * slope + minFontSize

  return `clamp( ${ minFontSize }rem, ${ yAxisIntersection }rem + ${ slope * 100 }vw, ${ maxFontSize }rem )`;
}
