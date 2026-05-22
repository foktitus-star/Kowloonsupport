Encoding.default_external = Encoding::UTF_8
require 'json'

# Original tracks
geojson_raw = File.read('/tmp/tracks_fixed.geojson')
data = JSON.parse(geojson_raw)

grid = {}
kept_features = []

data['features'].each do |f|
  next if f['geometry'].nil? || f['geometry']['type'] != 'LineString'
  coords = f['geometry']['coordinates']
  
  occupied_count = 0
  coords.each do |c|
    x = (c[0] / 0.0003).round
    y = (c[1] / 0.0003).round
    
    # Check 3x3 neighborhood in grid (~45m buffer)
    found = false
    (-1..1).each do |dx|
      (-1..1).each do |dy|
        if grid["#{x+dx},#{y+dy}"]
          found = true
          break
        end
      end
      break if found
    end
    occupied_count += 1 if found
  end
  
  if coords.length > 0 && (occupied_count.to_f / coords.length) > 0.45
    # duplicate track!
  else
    kept_features << f
    coords.each do |c|
      x = (c[0] / 0.0003).round
      y = (c[1] / 0.0003).round
      grid["#{x},#{y}"] = true
    end
  end
end

data['features'] = kept_features
new_geojson_str = JSON.generate(data)
puts "Grid filter kept #{kept_features.length} out of #{data['features'].length} features."

# Replace in HTML
file_path = './online_viewer.html'
html = File.read(file_path)

start_marker = "const localTracksGeoJson = "
start_idx = html.index(start_marker)
if start_idx
  start_idx += start_marker.length
  end_idx = html.index("};\n", start_idx) + 1
  new_html = html[0...start_idx] + new_geojson_str.force_encoding('UTF-8') + html[end_idx..-1]
  File.write(file_path, new_html)
  puts "Replaced!"
end
