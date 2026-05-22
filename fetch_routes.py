import urllib.request
import json
query = """
[out:json];
relation["route"="subway"](22.28,114.12,22.35,114.22);
out geom;
"""
url = "https://overpass-api.de/api/interpreter?data=" + urllib.parse.quote(query)
req = urllib.request.urlopen(url)
data = json.loads(req.read().decode('utf-8'))
features = []
for rel in data.get('elements', []):
    name = rel.get('tags', {}).get('name', 'MTR')
    coords = []
    # Collect coordinates from members
    for mem in rel.get('members', []):
        if mem['type'] == 'way' and 'geometry' in mem:
            way_coords = [[pt['lon'], pt['lat']] for pt in mem['geometry']]
            features.append({
                "type": "Feature",
                "properties": {"name": name},
                "geometry": {
                    "type": "LineString",
                    "coordinates": way_coords
                }
            })
geojson = {"type": "FeatureCollection", "features": features}
with open('routes.json', 'w') as f:
    json.dump(geojson, f)
print("Saved routes.json")
