require 'net/http'
require 'json'
require 'uri'

bounds = [
  [114.1718354, 22.3187498],
  [114.1664069, 22.3177560],
  [114.1662221, 22.3177229],
  [114.1660608, 22.3187120],
  [114.1607523, 22.3175839],
  [114.1579631, 22.3244827],
  [114.1604939, 22.3262772],
  [114.1635753, 22.3296807],
  [114.1679131, 22.3264821],
  [114.1703120, 22.3265165],
  [114.1718354, 22.3187498]
]

detailed_coords = []

(0...bounds.length-1).each do |i|
  p1 = bounds[i]
  p2 = bounds[i+1]
  
  uri = URI("http://router.project-osrm.org/route/v1/foot/#{p1[0]},#{p1[1]};#{p2[0]},#{p2[1]}?geometries=geojson&overview=full")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body)
  
  if data['code'] == 'Ok'
    route_coords = data['routes'][0]['geometry']['coordinates']
    # remove the last coord of the segment to avoid duplicating intersection points
    detailed_coords.concat(route_coords[0...-1])
  else
    detailed_coords << p1
  end
  sleep(0.5) # respect rate limit
end
detailed_coords << bounds.last

puts "detailed_coords.length = #{detailed_coords.length}"

# Replace inside html
file_path = './online_viewer.html'
html = File.read(file_path)

start_marker = "const boundingCoordinates = ["
start_idx = html.index(start_marker)
if start_idx
  end_idx = html.index("];", start_idx) + 2
  new_array_string = JSON.generate(detailed_coords)
  replacement = "const boundingCoordinates = #{new_array_string};"
  new_html = html[0...start_idx] + replacement + html[end_idx..-1]
  File.write(file_path, new_html)
  puts "Updated HTML with OSRM route."
end
