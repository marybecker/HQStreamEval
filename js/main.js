mapboxgl.accessToken = 'pk.eyJ1IjoibWFyeS1iZWNrZXIiLCJhIjoiY2p3bTg0bDlqMDFkeTQzcDkxdjQ2Zm8yMSJ9._7mX0iT7OpPFGddTDO5XzQ';

const map = new mapboxgl.Map({
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
                'id': 'simple-tiles',
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

// when the map is done loading
map.on('load', () => {

    // request JSON data
    d3.json('./data/catchments_hq.geojson').then((data) => {
        // when loaded

        const catchmentData = d3.json('./data/catchments_hq.geojson');
        const predictionData = d3.json('./data/pred_hq.json');
        const stateBoundaryData = d3.json('./data/ctStateBoundary.geojson');

        Promise.all([catchmentData, predictionData, stateBoundaryData]).then(addLayer);

    });

});

function addLayer(data){
    var cat   = data[0];
    var pred  = data[1];
    var bound = data[2];
    
    //cat['features'][i]['properties']['HydroID'] //get one data element
    //pred[j]['HydroID] //get one data element

    var k = 'HydroID';
    var cat_idx = {};
    for(var i=0; i<cat['features'].length; i++){
        var k_a = cat['features'][i]['properties'][k]; //get the hydro_id key for A[i]
        cat_idx[k_a] = i;                //key inserted into {} assign value i
    }
    for(var j=0; j<pred.length; j++){
        //add in check for existence or duplication with if/else...
        var k_b = pred[j][k];            //get the hydro_id key for B[j]
        cat['features'][cat_idx[k_b]]['properties']['pred'] = pred[j]; //insert B[j] into A[i]
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
                '#ca562c',
                0.5,
                '#70a494',
                1,
                '#008080',
            ]
          }
    });

    addInteraction('catLy')

}



function addInteraction(layer){

    document.getElementById('slider').addEventListener('input', (event) => {
        const year = event.target.value;
        if (year == 0) {
            r = 'hqp'
        }
        else {
            r = 'cfr_' + year
        }
        console.log(r);
        // update the map
        map.setPaintProperty(layer, 'fill-color', 
        [
            'interpolate',
            ['linear'],
            ['number', ['get',r, ['get','pred']]],
            0,
            '#ca562c',
            0.5,
            '#70a494',
            1,
            '#008080',
        ]);


        // // update text in the UI
        // document.getElementById('active-year').innerText = year;
    });
}

