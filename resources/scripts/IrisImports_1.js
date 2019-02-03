// Iris Container
class IrisContainer {
  constructor(parentNode,layoutOpts) {
    this.layout = {
      width: layoutOpts.width || 1226,
      height: layoutOpts.height || 717,
      margin: layoutOpts.margin || {t: 25, r: 25, b: 60, l: 60},
      font: {
        family: layoutOpts.font.family || "Times New Roman",
        size: layoutOpts.font.size || 16
      },
      yaxis: {
        title: layoutOpts.yaxis.title || "Y",
        zerolinecolor: layoutOpts.yaxis.zerolinecolor || "rgba(174,174,174,0.45)",
        zeroline: layoutOpts.yaxis.zeroline || true,
        scale: layoutOpts.yaxis.scale || "linear",
        grid: layoutOpts.yaxis.grid || false
      },
      xaxis: {
        title: layoutOpts.xaxis.title || "X",
        zerolinecolor: layoutOpts.xaxis.zerolinecolor || "rgba(174,174,174,0.45)",
        zeroline: layoutOpts.xaxis.zeroline || true,
        scale: layoutOpts.xaxis.scale || "linear",
        grid: layoutOpts.xaxis.grid || false
      }
    };
    this.layout.extents = {
      width: this.layout.width - this.layout.margin.l - this.layout.margin.r,
      height: this.layout.height - this.layout.margin.t - this.layout.margin.b
    };
    this.stylesElem = document.createElement("style");
    this.stylesElem.type = "text/css";
    this.stylesElem.innerHTML = this.styles;
    //bind styles to dom
    document.getElementsByTagName("head")[0].appendChild(this.stylesElem);

    // Set the parent and build the plot
    this.parent = d3.select(parentNode)
      .attr("width", `${this.layout.width}px`)
      .attr("height", `${this.layout.height}px`)
      .attr("class", "container")
      .style("display","block")
      .style("margin", "auto")
      .style("width", `${this.layout.width}px`)
      .style("height", `${this.layout.height}px`);
    // SVG
    this.svg = this.parent.append("svg")
        .attr("width", `${this.layout.width}px`)
        .attr("height", `${this.layout.height}px`)
        .attr("class", "svg-container")
        .attr("xmlns", "http://www.w3.org/2000/svg")
      .append("g")
        .attr("transform", `translate(${this.layout.margin.l},${this.layout.margin.t})`);
    this.svgX = this.svg.append("g")
      .attr("transform", `translate(0,${this.layout.extents.height})`)
      .attr("class", "axes x-axis");
    this.svgY = this.svg.append("g")
      .attr("class", "axes y-axis");
    this.xLabel = this.svg.append("g")
      .attr("class", "x-label");
    this.yLabel = this.svg.append("g")
      .attr("class", "y-label");
    // CANVAS
    this.linemap = this.parent.append("canvas")
      .attr("width", this.layout.width)
      .attr("height", this.layout.height-2)
      .style("margin", `${this.layout.margin.t+1}px ${this.layout.margin.r}px ${this.layout.margin.b}px ${this.layout.margin.l}px`)
      .attr("class", "canvas-container");
    // Map
    this.pointmap = this.parent.append("canvas")
      .attr("width", this.layout.width)
      .attr("height", this.layout.height-2)
      .style("margin", `${this.layout.margin.t+1}px ${this.layout.margin.r}px ${this.layout.margin.b}px ${this.layout.margin.l}px`)
      .attr("class", "pointmap-container")
      .attr("tabindex", "0");

    // Canvas Context
    this.linectx = this.linemap.node().getContext("2d");
    //clip the context
    this.linectx.rect(1,1,this.layout.extents.width-7,this.layout.extents.height-1);
    this.linectx.clip();
    
    this.pointctx = this.pointmap.node().getContext("2d");
    //clip the context
    this.pointctx.rect(1,1,this.layout.extents.width-7,this.layout.extents.height-1);
    this.pointctx.clip();

    this.databin = d3.select(document.createElement("custom"));
    this.pointbin = d3.select(document.createElement("custom"));
    
    this.dataBound = false;
  }// end Constructor
  

  // SET GET
  get styles() {
    return  `
      .container {
        width: ${this.layout.width}px !important;
        height:${this.layout.height}px !important;
      }
      .axes text {
        font-family: ${this.layout.font.family} !important;
        font-size: ${this.layout.font.size*0.9}pt !important;
        -webkit-touch-callout: none;
        -webkit-user-select: none;
        -khtml-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
      }
      .axes line {
        stroke-opacity: 0.6 !important;
        stroke: rgb(60,60,60) !important;
        stroke-width: 2px !important;
        shape-rendering: crispEdges !important;
      }
      .canvas-container, .svg-container, .pointmap-container {
        position: absolute !important;
        background-color: transparent !important;
      }
      .canvas-container {
        z-index: 100 !important;
      }
      .pointmap-container {
        z-index: 101 !important;
        cursor: move !important; /* fallback if grab cursor is unsupported */
        cursor: grab !important;
        cursor: -moz-grab !important;
        cursor: -webkit-grab !important;
      }
      .pointmap-container:active {
        cursor: grabbing !important;
        cursor: -moz-grabbing !important;
        cursor: -webkit-grabbing !important;
        outline: none !important;

      }
      .pointmap-container:focus {
        outline: none !important;
      }
      .x-label, .y-label {
        font-family: ${this.layout.font.family} !important;
        font-size: ${this.layout.font.size}pt !important;
      }
    `;
  }
  update(layout) {
    for (let prop in layout) {
      if (!layout.hasOwnProperty(prop)) continue;
      this.layout[prop] = layout[prop];
    }
    // update styles
    this.stylesElem.innerHTML = this.styles;

  }
  // Methods
  drawLabel(obj,g){
    const axClass = g.attr("class");
    let whichAx = axClass === "y-label"? "y-axis" : "x-axis";
    let gLab = g.selectAll("text")
      .data([{label:obj.layout[whichAx.replace(/[^0-9a-z]/gi,"")].title}]);
    if (whichAx === "y-axis") {
      gLab.enter()
        .append("text")
          .attr("transform", "rotate(-90)")
          .attr("x", -obj.layout.extents.height*12/13)
          .attr("dy", 20)
          .attr("fill", "rgba(30,30,30,0.6)")
          .attr("text-anchor","left")
          .attr("alignment-baseline","baseline")
        .merge(gLab)
          .text(d => d.label);
    } else {
      gLab.enter()
        .append("text")
          .attr("y", obj.layout.extents.height-5)
          .attr("x",obj.layout.extents.height/13)
          .attr("fill", "rgba(30,30,30,0.6)")
          .attr("text-anchor","left")
          .attr("alignment-baseline","baseline")
        .merge(gLab)  
          .text(d => d.label);
    }
    gLab.exit().remove();
  }
  // bind data
  bindData(inputData) {
    var that = this;
    return new Promise(
      (rv,rj) => {
        try {
          let lineBins = that.databin.selectAll("custom.lines")
            .data(inputData);
          let ptBins = that.pointbin.selectAll("custom.points")
            .data(d3.merge(inputData.map( dd => dd.x.map( 
                (v,i) => ({name:dd.name,mode:dd.mode,x:v,y:dd.y[i],marker:dd.marker}) 
              ))));
          // remove data
          lineBins.exit().remove();
          ptBins.exit().remove();
          // add/modify data
          lineBins
            .enter()
            .append("custom")
              .attr("class", "lines")
              .attr("lineInfo", d => JSON.stringify(d.line) )
              .attr("x", d => d.x )
              .attr("y", d => d.y )
              .attr("name", d => d.name )
              .attr("mode", d => d.mode )
            .merge(lineBins)
              .transition().duration(10)
              .attr("lineInfo", d => JSON.stringify(d.line) )
              .attr("x", d => d.x )
              .attr("y", d => d.y )
              .attr("name", d => d.name )
              .attr("mode", d => d.mode );
          
          ptBins
              .enter()
              .append("custom")
              .attr("class", "points")
              .attr("markerInfo", d => JSON.stringify(d.marker) )
              .attr("x", d => d.x )
              .attr("y", d => d.y )
              .attr("name", d => d.name )
              .attr("mode", d => d.mode )
            .merge(ptBins)
              .transition().duration(10)
              .attr("markerInfo", d => JSON.stringify(d.marker) )
              .attr("x", d => d.x )
              .attr("y", d => d.y )
              .attr("name", d => d.name )
              .attr("mode", d => d.mode );
          that.dataBound = true;
        } catch(ee) {
          rj(ee);
        }
        rv(true);
      }
        
    ); 
  }
  
} //endClass

// Iris Axes
class IrisAxes extends IrisContainer {
  constructor(data, ...containerArgs) {
    // container args should contain parent and layoutOpts or just parent
    super(...containerArgs);
    this.tooltipAt = [];
    var that = this;
    // bind data
    this.bindData(data).then( () => {that.dataBound = true;} );
  }
  // SET GET
  get domains() {
    const elems = this.databin.selectAll("custom.lines");
    let x = [], y = [];
    elems.each( d => {
      x.push(d.x);
      y.push(d.y);
    } );
    return {
      x: d3.extent(d3.merge(x)), 
      y: d3.extent(d3.merge(y)).map( (v,i,ar) => v + (!i ? -this.diff(ar)*0.05 : this.diff(ar)*0.05) )
    };
  }
  get xScale() {
    let xs = (this.layout.xaxis.scale === 'log') ? d3.scaleLog() : d3.scaleLinear();
    xs = xs
      .range([0,this.layout.extents.width])
      .domain(this.domains.x)
      .nice();
    return xs;
  }
  get yScale() {
    let ys = (this.layout.yaxis.scale === 'log') ? d3.scaleLog() : d3.scaleLinear();
    ys = ys 
      .range([this.layout.extents.height, 0])
      .domain(this.domains.y)
      .nice();
    return ys;
  }
  get xAxis() {
    return d3.axisBottom(this.xScale).ticks(9);
  }
  get yAxis() {
    return d3.axisLeft(this.yScale).ticks(5);
  }
  get zoomer() {
    const obj = this;
    return d3.zoom()
      .scaleExtent([0.9,100])
      .duration(700)
      .on("zoom", () => {
        const transform = d3.event.transform;
        obj.linectx.save();
        obj.draw(transform);
        obj.linectx.restore();
      });
  }

  // helpers
  init(){
    const obj = this;
    
    this.pointmap
      .call(this.zoomer)
      .on("dblclick.zoom", (d) => {
        const t = d3.zoomIdentity.translate(0,0).scale(1);
        obj.pointmap.transition()
           .duration(200)
           .ease(d3.easeLinear)
           .call(obj.zoomer.transform, t);
       });
    // draw
    this.draw(d3.zoomIdentity);
    this.pointmap
      .on("mousemove", () => {
        return obj.tooltipFinder(obj);
      });
  }
  draw(transform) {
    transform = transform || d3.zoomIdentity;
    //return false;
    const sX = transform.rescaleX(this.xScale);
    const sY = transform.rescaleY(this.yScale);

    // Labels
    let obj = this;
    this.xLabel.call((g)=> this.drawLabel(obj,g));
    this.yLabel.call((g) => this.drawLabel(obj,g));
    
    //
    this.svgX.call(this.xAxis.scale(sX));
    this.svgY.call(this.yAxis.scale(sY));
    // get transforms for clearing
    //let cT = this.linectx.getTransform();
    //let pT = this.pointctx.getTransform();
    this.linectx.clearRect(0,0,this.layout.extents.width,this.layout.extents.height);
    this.pointctx.clearRect(0,0,this.layout.extents.width,this.layout.extents.height);
    // draw the data bound to databin and pointbin
    this.drawLines(sX,sY,transform.k,this.linectx);
    // drawing points last draws them on top of the lines
    this.drawPoints(sX,sY,transform.k,this.linectx);
  }
  update(data,layout) {
    this.dataBound  =false;
    var obj = this;
    // update styles
    super.update(layout);
    this.bindData(data).then( () => {
      obj.dataBound = true;
      const t = d3.zoomIdentity.translate(0,0).scale(1);
        
      obj.pointmap.transition()
          .duration(5)
          .ease(d3.easeLinear)
          .call(obj.zoomer.transform, t);
      obj.draw(d3.zoomIdentity);
    } );
  }
  drawLines(sX,sY,kin,ctx) {
    const k = (kin > 1 ? kin * 0.75 : kin);
    const lineGen = d3.line()
      .x( d => sX(d.X) )
      .y( d => sY(d.Y) )
      .curve(d3.curveNatural)
      .context(ctx);
    // Update Grid------------------------------------------------------------------------------- GRID >
    if (this.layout.yaxis.grid || this.layout.xaxis.grid) {
      // draw grid lines
      if (this.layout.yaxis.grid){
        // draw y grid (horizontal)
        const yticks = this.yAxis.scale(sY).scale().ticks(5);
        ctx.restore();
        for (let yy in yticks){
          ctx.beginPath();
          ctx.setLineDash(this.strokeType("solid"));
          ctx.moveTo(0,sY(yticks[yy]));//X=min,Y=tick
          ctx.lineTo(this.layout.extents.width, sY(yticks[yy]));
          ctx.strokeStyle = "rgba(10,10,40,0.1)";
          ctx.lineWidth = 1;
          ctx.stroke();
        }
        ctx.save();
      }
      if (this.layout.xaxis.grid){
        // draw x grids (vertical)
        const xticks =this.xAxis.scale(sX).scale().ticks(9);
        ctx.restore();
        for (let xx in xticks){
          ctx.beginPath();
          ctx.setLineDash(this.strokeType("solid"));
          ctx.moveTo(sX(xticks[xx]), 0);//X=tick,y=min
          ctx.lineTo(sX(xticks[xx]), this.layout.extents.height);
          ctx.strokeStyle = "rgba(10,10,40,0.1)";
          ctx.lineWidth = 1;
          ctx.stroke();
        }
        ctx.save();
        
      }
    }
    // Update Zeros -------------------------------------------------------------------------- ZERO >
    if (this.layout.yaxis.zeroline || this.layout.xaxis.zeroline) {
      // draw zero lines
      if (this.layout.yaxis.zeroline){
        // draw y zero (horizontal)
        ctx.restore();
        ctx.beginPath();
        ctx.setLineDash(this.strokeType("solid"));
        ctx.moveTo(0,sY(0));
        ctx.lineTo(this.layout.extents.width, sY(0));
        ctx.strokeStyle = this.layout.yaxis.zerolinecolor;
        ctx.lineWidth = 1.5*k;
        ctx.stroke();
        ctx.save();
      }
      if (this.layout.xaxis.zeroline){
        // draw x zero (vertical)
        ctx.restore();
        ctx.beginPath();
        ctx.setLineDash(this.strokeType("solid"));
        ctx.moveTo(sX(0), 0);
        ctx.lineTo(sX(0), this.layout.extents.height);
        ctx.strokeStyle = this.layout.xaxis.zerolinecolor;
        ctx.lineWidth = 1.5*k;
        ctx.stroke();
        ctx.save();
        
      }
    }
    // DATA -------------------------------------------------------------------------- DATA >
    const elems = this.databin.selectAll("custom.lines");
    elems.each( dat => {
      if(!/lines/gi.test(dat.mode)){ 
        return;
      }
      ctx.beginPath();
      lineGen( 
        dat.x.map( 
          (x,i) => ({"X":x, "Y":dat.y[i]}) 
        ) 
      );
      ctx.lineWidth = dat.line.width*k;
      ctx.lineCap="round";
      ctx.setLineDash(this.strokeType(dat.line.style).map( v => v*k ));
      ctx.strokeStyle = this.rgb2A(dat.line.color, dat.line.hasOwnProperty("opacity") ? dat.line.opacity : 1);
      ctx.shadowOffsetX = 1.5*k;
      ctx.shadowOffsetY = 2.5*k;
      ctx.shadowBlur    = 5*k;
      ctx.shadowColor   = "rgba(104, 104, 104, 0.25)";
      ctx.stroke();
    });
  }
  drawPoints(sX,sY,k,ctx) {
    //points drawn to scales
    let pointGen = d3.symbol().context(ctx);
    const elems = this.pointbin.selectAll("custom.points");

    elems.each( d => {
      // each d in elems contains the stored data
      if(!/markers/gi.test(d.mode)){ 
        return;
      }
      ctx.save();
      ctx.fillStyle = this.rgb2A(d.marker.color, d.marker.hasOwnProperty("opacity") ? d.marker.opacity : 1);
      ctx.translate(sX(d.x),sY(d.y));
      ctx.beginPath();
      pointGen.type(this.markerType(d.marker.symbol)).size(d.marker.size**2 * (k>1?k*0.75:k))(d);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    });
  }
  //static
  diff(arr) {
    let i = 0;
    let result = [];
    while (i < arr.length-1) {
      result.push(arr[++i] - arr[i-1]);
    }
    return result;
  }
  rgb2A(col,opc) {
    let rgb = col.split(",").map( v => v.replace(/\D/g,"") );
    return `rgba(${rgb.slice(0,3).concat(opc.toString()).join(",")})`
  }
  strokeType(type) {
    switch (type.toLowerCase()) {
      case "solid":
        return [0];
      case "dashed":
        return [18,12];
      case "dotted":
        return [2,8];
      case "dashed-dotted":
        return [18,10,1,8,1,10];
    }
  }
  markerType(type){
    type = type || "circle";
    switch (type.toLowerCase()) {
      case "cross":
        return d3.symbolCross;
      case "diamond":
        return d3.symbolDiamond;
      case "square":
        return d3.symbolSquare;
      case "star":
        return d3.symbolStar;
      case "y":
        return d3.symbolWye;
      case "triangle":
        return d3.symbolTriangle;
      default:
        // circle is default if type is not there
        return d3.symbolCircle;
    }
  }
  // TOOLTIPS
  tooltipDelay(func,delay,obj) {
    let prev = Date.now() - delay;
    return (...args) => {
      let cur = Date.now();
      if (cur-prev >= delay) {
        prev = cur;
        func.apply(args[2][0],args,obj);
      } else {
        obj.pointctx.clearRect(0,0,obj.layout.width,obj.layout.height);
      }
    }
  }
  tooltipFinder(obj) {
    
    let cLocation = d3.mouse(obj.pointmap.node());
    
    let currentZoom = d3.zoomTransform(obj.pointmap.node());
    let sx = currentZoom.rescaleX(obj.xScale);
    let sy = currentZoom.rescaleY(obj.yScale);
    let k = currentZoom.k;
    //setup an aray to push the points to when > 1 point matches... i.e. two line pts.
    let tooltipData = [];
    // get the "points" data
    const elems = obj.pointbin.selectAll("custom.points");
    // check the distance between current location and all points.
    elems.each( (d) => {
      let dx = sx(d.x) - cLocation[0];
      let dy = sy(d.y) - cLocation[1];
      // Check distance and return if cursor is too far from the point.
      if ( Math.sqrt(dx**2 + dy**2) > Math.sqrt(d.marker.size**2 * (k>1?k*0.75:k)) ) return false;
      // close enough, push tooltip data
      tooltipData.push(d);
    });
    
    // check if we didnt" find anything
    if (!tooltipData.length) {
      obj.tooltipAt = [];
      //obj.pointctx.resetTransform();
      obj.pointctx.setTransform(1,0,0,1,0,0);
      
      obj.pointctx.clearRect(0,0,obj.layout.width,obj.layout.height);
      
      return false;
    }
    
    if (tooltipData.length > 1) {
      
      // filter to grab a single point from each
      let checkIndex = tooltipData.map(d => d.name);
      checkIndex = checkIndex.map( (v,i,a) => a.indexOf(v)===i );
      tooltipData = tooltipData.filter((dat,ind) => checkIndex[ind]);
    }
    
    const pxDat = [parseInt(sx(tooltipData[0].x)),parseInt(sy(tooltipData[0].y))];
    if (obj.tooltipAt.length && pxDat.reduce( (b,v,i) => b = (b && (v === obj.tooltipAt[i])), true)) {
      return false;
    }
    
    // start by just plotting the first found tooltip.
    var dirStr = "";
    dirStr += (pxDat[1] < obj.layout.extents.height/2) ? "s" : "n";
    dirStr += (pxDat[0] < obj.layout.extents.width/2)  ? "e" : "w" ;
    
    // set transform and check if it applied
    
    obj.pointctx.setTransform(1,0,0,1,pxDat[0],pxDat[1]);
    const currentTrs = obj.pointctx.getTransform();
    
    if ((currentTrs.e !== pxDat[0] && currentTrs.f !== pxDat[1])) {
      obj.pointctx.setTransform(1,0,0,1,0,0);
      obj.pointctx.clearRect(0,0,obj.layout.width,obj.layout.height);
      return false;
    }
    obj.pointctx.clearRect(-currentTrs.e,-currentTrs.f,obj.layout.width,obj.layout.height);
    obj.makeTooltip(tooltipData,obj.pointctx,dirStr);
    obj.tooltipAt = pxDat;
  }
  makeTooltip(tipObjArray,cx,direction) {
    if (!tipObjArray) return false;
    // Tooltips will be draw at <0,0> and thus need a transformation to move
    // Direction is relative to <0,0>, the point of growth.
    // Directions can be: nw,ne,sw,se... eventually n,s,w,e will be acceptable.
    const N = tipObjArray.length;
    const currentTransform = cx.getTransform();
    const contextDims = {
      x0: currentTransform.e,
      y0: currentTransform.f,
      width: cx.canvas.clientWidth,
      height: cx.canvas.clientHeight
    };
    
    const tipOfst = 19;
    const tipBetween = 10;
    const tipTextField = 66;
    const tipTextWidth = N * tipTextField + (N-1)*tipBetween;
    const tipBoxWidth = tipTextWidth + 2*tipOfst;
    const boxOfst = 10;
    const radiusOfst = 25;
    const tipDims = {width: tipBoxWidth+2*boxOfst, height: 80};
    const boxHeight = tipDims.height - 2*boxOfst - 4; //4 = 2px*2 for each border
    // animation properties
    const ease = d3.easeBounce;
    const dur = 200;
    // Scale pattern for directional positioning
    let sc = [1,1];
    
    switch (direction) {
      case "nw":
        sc = [-1,-1];
        break;
      case "ne":
        sc[1] = -1;
        break;
      case "se":
        // default do nothing with scale
        break;
      case "sw":
        sc[0] = -1;
        break;
    }
    // make the drawing data
    const pts = d3.range(10).map( v => ( {x:0, y:0}) );
    const box = [
        {x:   3, y:  3},
        {x:  radiusOfst, y: boxOfst},
        {x: tipDims.width-radiusOfst, y: boxOfst},
        {x: tipDims.width-boxOfst, y: radiusOfst},
        {x: tipDims.width-boxOfst, y: tipDims.height-radiusOfst},//55},
        {x: tipDims.width-radiusOfst, y: tipDims.height-boxOfst},//70},
        {x:  radiusOfst, y: tipDims.height-boxOfst},//70},
        {x:  boxOfst, y: tipDims.height-radiusOfst},//55},
        {x:  boxOfst, y: radiusOfst},
        {x:   3, y:  3}
      ];
    const r1 = 7;
    const r2 = 12;
    // COLORS  ----------------------!!
    // get the color stops
    let stops = d3.merge(d3.range(N).map( (v,i) => [v/N, v/N+1/(N**2)] ));
    stops.push(1);
    stops.splice(Math.floor(stops.length/2),1);
    stops = stops.reduce( (r,k,i) => (!(i%2) ? r.push([k]):r[r.length-1].push(k)) && r, []);
     
    let grad = cx.createLinearGradient(boxOfst+tipOfst,0,tipDims.width-boxOfst-tipOfst,0);
    stops.forEach( (arr,i) => {
      const ind = ( sc[0] === -1 ? N-1-i : i );
      grad.addColorStop(arr[0], this.rgb2A(tipObjArray[ind].marker.color,0.16) );
      grad.addColorStop(arr[1], this.rgb2A(tipObjArray[ind].marker.color,0.16) );
    } );
    const fillColor = grad;//"rgba(200,200,200,0.55)";
    const strokeColor = "rgba(150,150,150,0.65)";
    // --------------------------------------------!!
    
    animate();
    // FUNCTIONS ----------------------------------------------------->
    function draw() {
      //cx.restore();
      // clear the canvas
      cx.clearRect(-contextDims.x0,-contextDims.y0,contextDims.width,contextDims.height);
      // Draw the box
      cx.beginPath();
      cx.moveTo(pts[0].x,pts[0].y);
      cx.bezierCurveTo(pts[0].x+r1/2,pts[0].y+r1/2,pts[1].x-r1/2,pts[1].y, pts[1].x,pts[1].y);
      cx.lineTo(pts[2].x,pts[2].y);
      cx.bezierCurveTo(pts[2].x+r2,pts[2].y,pts[3].x,pts[3].y-r2,pts[3].x,pts[3].y);
      cx.lineTo(pts[4].x,pts[4].y);
      cx.bezierCurveTo(pts[4].x, pts[4].y+r2, pts[5].x+r2, pts[5].y, pts[5].x, pts[5].y);
      cx.lineTo(pts[6].x,pts[6].y);
      cx.bezierCurveTo(pts[6].x-r2, pts[6].y, pts[7].x, pts[7].y+r2, pts[7].x, pts[7].y);
      cx.lineTo(pts[8].x,pts[8].y);
      cx.bezierCurveTo(pts[8].x,pts[8].y-r1/2,pts[9].x+r1/2,pts[9].y, pts[9].x,pts[9].y);
      cx.closePath();
      cx.shadowOffsetX = 1.5;
      cx.shadowOffsetY = 2.5;
      cx.shadowBlur    = 5;
      cx.shadowColor   = "rgba(104, 104, 104, 0.25)";
      cx.stroke();
      cx.fill();
      //cx.save();
    }
    
    function animate() {
      // Interpolates all the points from <0,0> to the tip box shape
      // store current source
      pts.forEach( (p,i) => {
        p.sx = p.x;
        p.sy = p.y;
        p.tx = box[i].x;
        p.ty = box[i].y;
      } );
      
      
      cx.beginPath();
      cx.strokeStyle = strokeColor;
      cx.fillStyle = fillColor;
      cx.lineWidth = 2;
      // move/scale according to direction
      //cx.translate(st[0],st[1]);
      cx.scale(sc[0],sc[1]);
      // clip the drawing to required tip bounds
      cx.save();
      cx.beginPath();
      cx.rect(0,0,tipDims.width,tipDims.height);
      cx.clip();
      // run animation
      var timer = d3.timer( (els) => {
        const t = Math.min(1,ease(els/dur));
        //interp
        pts.forEach( pt => {
          pt.x = pt.sx*(1-t) + pt.tx*t;
          pt.y = pt.sy*(1-t) + pt.ty*t;
        } );
        // update graph
        draw();
        
        if (t === 1) {
          timer.stop();
          //addText
          // need to flip back to normal for correct text
          
          cx.scale(sc[0],sc[1]);
          // draw the text elements
          cx.beginPath();
          for(let i=0; i<tipObjArray.length; i++){
            drawText(i);
          }
          
          // drop the clip and restore the canvas
          cx.restore();
          //console.log("x:"+("       "+tipObjArray[0].x.toPrecision(3)).slice(-7));
        }
      } );
      
    }
    function drawText(i){
      //X-position: make N spaces, 5px between and find the centers of the spaces
      const xPos = sc[0]*parseInt(tipTextField/2*(i+(i+1)) + i*tipBetween + tipOfst + boxOfst);
      //Y-position: contract the box by 20px, find 3 equal spots, then find the centers of each
      const ypad = 10;
      //var yPos = d3.range(3).map(v=> Math.round((boxHeight-20)/3*(v+(v+1)/3) + boxOfst + 10));
      var yPos = d3.range(3).map( v => ((boxHeight-2*ypad) * (4*v+1) / 9) + boxOfst+ypad)
      yPos = sc[1] < 0 ? yPos.reverse() : yPos;
      const ind = ( sc[0] === -1 ? N-1-i : i );
      const txDat = {
        id:"ID:"+("              "+tipObjArray[ind].name).slice(-9),
        x: "x:"+("       "+tipObjArray[ind].x.toPrecision(3)).slice(-7),
        y: "y:"+("       "+tipObjArray[ind].y.toPrecision(3)).slice(-7),
        color: tipObjArray[ind].marker.color//"rgba(10,10,10,0.9)"
      };
      // ID LABEL
      cx.textAlign = "center";
      cx.textBaseline = "middle";
      cx.font = "10pt Times New Roman";
      cx.fillStyle = txDat.color;
      cx.fillText(
        txDat.id, 
        xPos,//tipDims.width/2*0.99, 
        sc[1]*yPos[0]//tipDims.height/2*0.7
      );
      // X POSITION
      cx.textAlign = "center";
      cx.textBaseline = "middle";
      cx.font = "12pt Times New Roman";
      cx.fillText(
        txDat.x, 
        xPos,//tipDims.width/2*0.99, 
        sc[1]*yPos[1],//tipDims.height/2,
        66
      );
      // Y POSITION
      cx.font = "12pt Times New Roman";
      cx.textAlign = "center";
      cx.textBaseline = "middle";
      cx.fillText(
        txDat.y, 
        xPos,//tipDims.width/2*0.99, 
        sc[1]*yPos[2],//tipDims.height/2*1.25,
        66
      );
    }
    // <----------------------------------------------------------------
  }
}