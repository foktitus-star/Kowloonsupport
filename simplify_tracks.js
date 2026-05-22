const fs = require('fs');
const file = './online_viewer.html';
let html = fs.readFileSync(file, 'utf8');

const marker = "const localTracksGeoJson = ";
const start = html.indexOf(marker) + marker.length;
const end = html.indexOf("};\n", start) + 1;

const jsonStr = html.substring(start, end);
const data = JSON.parse(jsonStr);

let grid = {};
let keptFeatures = [];

// Sort by length to keep the longest, cleanest line of a pair
data.features.sort((a,b) => b.geometry.coordinates.length - a.geometry.coordinates.length);

data.features.forEach(f => {
    const coords = f.geometry.coordinates;
    let occupied = 0;
    
    // Check points
    coords.forEach(c => {
        const x = Math.round(c[0] / 0.0003);
        const y = Math.round(c[1] / 0.0003);
        
        let found = false;
        for(let dx=-1; dx<=1; dx++){
            for(let dy=-1; dy<=1; dy++){
                if (grid[`${x+dx},${y+dy}`]) {
                    found = true; break;
                }
            }
            if (found) break;
        }
        if (found) occupied++;
    });
    
    // If more than 40% of the line vertices are within ~40m of existing track, drop
    if (coords.length > 0 && occupied / coords.length > 0.4) {
        // Drop parallel
    } else {
        keptFeatures.push(f);
        coords.forEach(c => {
            const x = Math.round(c[0] / 0.0003);
            const y = Math.round(c[1] / 0.0003);
            grid[`${x},${y}`] = true;
        });
    }
});

console.log(`Kept ${keptFeatures.length} out of ${data.features.length}`);
data.features = keptFeatures;

const newJsonStr = JSON.stringify(data);
const newHtml = html.substring(0, start) + newJsonStr + html.substring(end);
fs.writeFileSync(file, newHtml, 'utf8');
