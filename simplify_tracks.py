import json

with open('./online_viewer.html', 'r', encoding='utf-8') as f:
    html = f.read()

start_marker = "const localTracksGeoJson = "
start_idx = html.find(start_marker)
if start_idx == -1:
    print("Cannot find GeoJSON")
    exit(1)

start_idx += len(start_marker)
# Find the matching semicolon or script end
end_idx = html.find("};\n", start_idx) + 1

geojson_str = html[start_idx:end_idx]
print(f"GeoJSON len: {len(geojson_str)}")

data = json.loads(geojson_str)

# Strategy: for each line string, check if its midpoint is within 0.0004 deg (approx 40m) of an already accepted line segment.
import math
def get_midpoint(coords):
    if not coords: return (0,0)
    idx = len(coords) // 2
    return coords[idx]

def dist(p1, p2): # approx degrees
    return math.hypot(p1[0]-p2[0], p1[1]-p2[1])

kept_features = []
for f in data['features']:
    if f['geometry']['type'] != 'LineString': continue
    coords = f['geometry']['coordinates']
    mid = get_midpoint(coords)
    
    # check distance to all kept
    is_duplicate = False
    for kf in kept_features:
        if f['properties'].get('name') and kf['properties'].get('name') and f['properties']['name'] != kf['properties']['name']:
            continue # Different line names
            
        kf_mid = get_midpoint(kf['geometry']['coordinates'])
        if dist(mid, kf_mid) < 0.0006: # ~60m distance
            # Also check if they roughly start/end near each other to ensure it's parallel
            start_dist1 = dist(coords[0], kf['geometry']['coordinates'][0])
            start_dist2 = dist(coords[0], kf['geometry']['coordinates'][-1])
            if start_dist1 < 0.001 or start_dist2 < 0.001:
                is_duplicate = True
                break
                
    if not is_duplicate:
        kept_features.append(f)

data['features'] = kept_features
new_geojson_str = json.dumps(data)
print(f"Kept {len(kept_features)} out of {len(data['features'])} lines.")

# Replace in HTML
new_html = html[:start_idx] + new_geojson_str + html[end_idx:]

with open('./online_viewer.html', 'w', encoding='utf-8') as f:
    f.write(new_html)

print("Simplified tracks saved.")
