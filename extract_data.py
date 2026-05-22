import xml.etree.ElementTree as ET
import json
import traceback

def parse_osm(osm_file, out_file):
    print("Reading node coordinates...")
    nodes = {}
    features = []
    
    try:
        # First pass: collect node coordinates and node features
        context = ET.iterparse(osm_file, events=('end',))
        for event, elem in context:
            if elem.tag == 'node':
                node_id = elem.attrib['id']
                lon = float(elem.attrib['lon'])
                lat = float(elem.attrib['lat'])
                nodes[node_id] = (lon, lat)
                
                tags = {child.attrib['k']: child.attrib['v'] for child in elem if child.tag == 'tag'}
                
                # Filter for subway/train stations
                is_station = False
                if tags.get('railway') in ('station', 'stop') or tags.get('subway') == 'yes' or tags.get('public_transport') == 'station':
                    is_station = True
                
                if is_station:
                    feat = {
                        "type": "Feature",
                        "geometry": {"type": "Point", "coordinates": [lon, lat]},
                        "properties": {
                            "type": "station",
                            "name": tags.get("name", "Unknown Station"),
                            "name:en": tags.get("name:en", "")
                        }
                    }
                    features.append(feat)
                elem.clear()
            elif elem.tag in ('way', 'relation'):
                elem.clear()
        
        print(f"Collected {len(nodes)} nodes. Parsing ways...")
        
        # Second pass: trace ways for streets and buildings
        context = ET.iterparse(osm_file, events=('end',))
        way_count = 0
        for event, elem in context:
            if elem.tag == 'way':
                tags = {child.attrib['k']: child.attrib['v'] for child in elem if child.tag == 'tag'}
                is_building = 'building' in tags
                is_highway = 'highway' in tags
                
                if is_building or is_highway:
                    nds = [child.attrib['ref'] for child in elem if child.tag == 'nd']
                    coords = []
                    for nd in nds:
                        if nd in nodes:
                            coords.append(nodes[nd])
                    
                    if len(coords) >= 2:
                        geom_type = "LineString"
                        
                        # Closed ring Check to upgrade to Polygon
                        if is_building and coords[0] == coords[-1] and len(coords) >= 4:
                            geom_type = "Polygon"
                            coords = [coords] # Polygon outer ring
                            
                        feat_type = "building" if is_building else "street"
                        
                        # Keep it simple, just take the localized or basic name
                        feat_name = tags.get("name", tags.get("name:en", ""))
                        
                        feat = {
                            "type": "Feature",
                            "geometry": {"type": geom_type, "coordinates": coords},
                            "properties": {
                                "type": feat_type,
                                "name": feat_name
                            }
                        }
                        features.append(feat)
                        way_count += 1
                elem.clear()
            elif elem.tag in ('node', 'relation'):
                elem.clear()
                
        print(f"Extracted {way_count} ways. Writing GeoJSON...")
        
        geojson = {
            "type": "FeatureCollection",
            "features": features
        }
        
        with open(out_file, 'w', encoding='utf-8') as f:
            json.dump(geojson, f)
            
        print("Done. Saved to map-data.geojson")
        
    except Exception as e:
        print("An error occurred:")
        traceback.print_exc()

if __name__ == "__main__":
    parse_osm("map-13.osm", "map-data.geojson")
