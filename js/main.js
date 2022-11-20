mapboxgl.accessToken = 'pk.eyJ1IjoibWFyeS1iZWNrZXIiLCJhIjoiY2p3bTg0bDlqMDFkeTQzcDkxdjQ2Zm8yMSJ9._7mX0iT7OpPFGddTDO5XzQ';

var map = new mapboxgl.Map({
    container: 'map', // container ID
    style: {
        'version': 8,
        'sources': {
            'raster-tiles': {
                'type': 'raster',
                'tiles': [
                    'https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/tile/{z}/{y}/{x}'
                ],
                'tileSize': 256,
                'attribution':
                    'USGS The National Map: National Hydrography Dataset'
            }
        },
        'layers': [
            {
                'id': 'nhd',
                'type': 'raster',
                'source': 'raster-tiles',
                'minzoom': 0,
                'maxzoom': 17
            }
        ]
    },
    center: [-72.65, 41.55], // starting position
    zoom: 8.5 // starting zoom
});


map.fitBounds([[-73.727775, 40.980144], [-71.786994, 42.050587]], 
    {padding: {top: 100, bottom:10, left: 5, right: 5}});
// Create a popup, but don't add it to the map yet.

var popup = new mapboxgl.Popup({
    className: 'sitePopup',
    closeButton: false,
    closeOnClick: false
});

// when the base map is done loading
map.on('load', () => {
    // async load the JSON data
    var catchmentData = d3.json('./data/catchments_hq.geojson');
    var predictionData = d3.json('./data/pred_hq.json');
    var stateBoundaryData = d3.json('./data/ctStateBoundary.geojson');
    var predictionLengthData = d3.json('./data/length_hq.json')
    Promise.all([catchmentData, predictionData, stateBoundaryData, predictionLengthData]).then(addMapLayers);
});

function addMapLayers(data){
    //data = [catchmentData, predictionData, stateBoundaryData]; from line 47
    var cat   = data[0];
    var pred  = data[1];
    var bound = data[2];
    var lpred = data[3];
    console.log(pred);
    //console.log(lpred['HydroID']['']);
    
    var k = 'HydroID';
    var cat_idx = {};
    for(var i=0; i<cat['features'].length; i++){
        var k_a = cat['features'][i]['properties'][k]; //get the hydro_id key for A[i]
        cat_idx[k_a] = i;                              //key inserted into {} assign value i
    }
    for(var j=0; j<pred.length; j++){                                  //add in check for existence or duplication with if/else...
        var k_b = pred[j][k];                                          //get the hydro_id key for B[j]
        cat['features'][cat_idx[k_b]]['properties']['pred'] = pred[j]; //insert B[j] into A[i] #check this for string?
    }

    for(var j=0; j<lpred.length; j++){                                  //add in check for existence or duplication with if/else...
        var k_b = lpred[j][k];                                          //get the hydro_id key for B[j]
        cat['features'][cat_idx[k_b]]['properties']['lpred'] = lpred[j]; //insert B[j] into A[i] #check this for string?
    }
    console.log(cat);
    map.addSource('cat', {
        type: 'geojson',
        data: cat
    })

    map.addSource('bound', {
        type: 'geojson',
        data: bound
    })

    map.addLayer({
        'id': 'boundaryLy',
        'type': 'line',
        'source': 'bound',
        'paint': {
            'line-width': 1,
        // Use a get expression (https://docs.mapbox.com/mapbox-gl-js/style-spec/#expressions-get)
        // to set the line-color to a feature property value.
            'line-color': '#333333'
        }
    });

    map.addLayer({
        'id': 'catLy',
        'type': 'fill',
        'source': 'cat',
        paint: {
            'fill-color': [
                'interpolate',
                ['linear'],
                ['number', ['get','hqp', ['get','pred']]],
                0,
                '#df5a00',
                0.5,
                '#3f7ea6',
                1,
                '#023059',
            ],
            'fill-opacity': 0.7
          }
    });

    addSliderInteraction('catLy', cat)
    addPopup('catLy', 0) //Popup on load before interaction
    drawPlot(cat, 0)


}



function addSliderInteraction(layer, data){
    document.getElementById('slider').addEventListener('input', (event) => {
        var reduction = event.target.value;
        console.log(reduction);

        // get the amount of coreforest reduction
        if (reduction == 0) {var r = 'hqp'}
        else {var r = 'cfr_' + reduction}

        // update the map
        map.setPaintProperty(layer, 'fill-color', 
        [
            'interpolate',
            ['linear'],
            ['number', ['get',r, ['get','pred']]],
            0,
            '#df5a00',
            0.25,
            '#ff9528',
            0.6,
            '#3f7ea6',
            0.75,
            '#023059',
        ]);


        // update text in the slider UI
        document.getElementById('reduction').innerText = reduction + '% Core Forest Reduction';
        
        s = getStreamLength(data, 'hqp') - getStreamLength(data, r)
        spct = Math.round (100 - (getStreamLength(data, r) / getStreamLength(data, 'hqp') * 100))
        document.getElementById('loss').innerText = `${Math.round(s)} Kilometers Lost Statewide (${spct}%)`;


        addPopup(layer, reduction)
        //d3.select('#Plot').html('') //delete everything in div=id Plot
        //d3.select().text('')
        //d3.select().style()
        //d3.select().attr({'class':'new'}) //set the class
        //d3.select().attr({'id':'div1'})
        document.getElementById('Plot').innerHTML = ''
        drawPlot(data, reduction)

    });
}

function addPopup(layer, reduction){
    // get the amount of coreforest reduction
    if (reduction == 0) {r = 'hqp'}
    if (reduction > 0)  {r = 'cfr_' + reduction}
    

    map.on('mouseover', layer, function(e) {
        var p = JSON.parse(e.features[0].properties.pred);
        var s = getStreamConditionTxt(p[r]);
        var l = JSON.parse(e.features[0].properties.lpred);
        var lr = 'l_cfr_' + reduction;
        var ll = Math.round(l['l_cfr_0'] - l[lr]);
        var llpct = Math.round(100 - ((l[lr] / l['l_cfr_0']) * 100));
        console.log(l['l_cfr_0'] - l[lr]);
        var popupInfo = `<b>Core Forest Reduction:</b> ${reduction}%<br> <b>Probability HQ:</b> ${s} (${p[r]})<hr><b>HQ Lost in Upstream Drainage Basin:</b> ${ll} Kilometers (${llpct}%)`;
        console.log(popupInfo);//duplicating info for each event.  Need to figure out how to remove
        
        // When a hover event occurs on a feature,
        // open a popup at the location of the hover, with description
        // HTML from the hover event's properties.
        popup.setLngLat(e.lngLat).setHTML(popupInfo).addTo(map);
    });

    // Change the cursor to a pointer when the mouse is over.
    // map.on('mousemove', layer, () => {
    //     map.getCanvas().style.cursor = 'pointer';
    // });

    // Change the cursor back to a pointer when it leaves the point.
    map.on('mouseleave', layer, () => {
        map.getCanvas().style.cursor = '';
        popup.remove();
    });
}

function getStreamLength(data, p){
    var sum_length = 0;
    for(var i=0; i<data['features'].length; i++){
        var j = data['features'][i]['properties']['pred'][p];
        var l = data['features'][i]['properties']['pred']['cat_length_km'];
        
        if(j > 0.5 && sum_length == 0){sum_length = l}
        else if(j > 0.5){sum_length = sum_length + l}
        
    }
    return sum_length;
}

function getStreamConditionTxt(data){
    if(data < 0.25){return 'Very Low'}
    if(data > 0.25 && data < 0.5){return 'Low'}
    if(data > 0.5 && data < 0.75){return 'High'}
    if(data > 0.75){return 'Very High'}
}

function drawPlot(cat, reduction){
    var hqKm = [];
    for (var i=0; i < 21; i ++){
        if (i == 0){
            hqKm.push({id:i, km:getStreamLength(cat, 'hqp')})
        }
        else {
            hqKm.push({id:i, km:getStreamLength(cat, 'cfr_' + i.toString())})
        }
    }

    var n = Number(reduction);

    var hqPlot = Plot.plot({
        grid: true,
        width: 275,
        height: 200,
        x: {label: `← Kilometers of High Quality Stream`, reverse: true, labelAnchor: 'right'},
        y: {label: `↑ % Core Forest Reduction`},
        marks: [
            Plot.areaY(hqKm, {y: "id", x: "km", fill: "#df5a00", filter: (d) => d.id <= n}),
            Plot.line(hqKm, {y: "id", x: "km"}),
            Plot.dot(hqKm, {y: "id", x: "km"}),
            Plot.dot(hqKm, {y: "id", x: "km", r: 8, fill: "#023059", filter: (d) => d.id === n})
        ],
        style: {
            background: "#333333",
            fontSize: 500,
            color: "white",
            padding: "1px"
        }
    })

    document
        .querySelector("#Plot")
        .appendChild(hqPlot)
}




