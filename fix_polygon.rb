require 'net/http'
require 'json'
require 'uri'

# P1 to P9 points
p1_nelson_saiyee = [114.171835, 22.318750]
p2_nelson_ferry = [114.166407, 22.317756]
p3_tongmi_cherry = [114.166061, 22.318712]
p4_cherry_shammong = [114.160752, 22.317584]
p5_shammong_chuiyu = [114.157963, 22.324483]
p6_chuiyu_namcheong = [114.160494, 22.326277]
p7_namcheong_csw = [114.163575, 22.329681]
p8_csw_boundary = [114.167913, 22.326482]
p9_boundary_saiyee = [114.170312, 22.326516]

def route_osrm(pA, pB)
  uri = URI("http://router.project-osrm.org/route/v1/foot/#{pA[0]},#{pA[1]};#{pB[0]},#{pB[1]}?geometries=geojson&overview=full")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body)
  if data['code'] == 'Ok'
    return data['routes'][0]['geometry']['coordinates'][0...-1] # skip last point
  end
  return [pA]
end

detailed = []

# Straight cut along Nelson Street
detailed << p1_nelson_saiyee
detailed << p2_nelson_ferry

# Straight cut from Ferry up to Tong Mi Road
detailed << p3_tongmi_cherry

# Complex curvature roads: OSRM
detailed.concat(route_osrm(p3_tongmi_cherry, p4_cherry_shammong))
sleep(0.5)
detailed.concat(route_osrm(p4_cherry_shammong, p5_shammong_chuiyu))
sleep(0.5)
detailed.concat(route_osrm(p5_shammong_chuiyu, p6_chuiyu_namcheong))
sleep(0.5)
detailed.concat(route_osrm(p6_chuiyu_namcheong, p7_namcheong_csw))
sleep(0.5)
detailed.concat(route_osrm(p7_namcheong_csw, p8_csw_boundary))

# From Cheung Sha Wan Rd, head east along Boundary St as straight line
detailed << p8_csw_boundary

# From Boundary straight to Sai Yee, straight line
detailed << p9_boundary_saiyee

# Loop back to P1 (Nelson / Sai Yee)
detailed << p1_nelson_saiyee

puts "detailed array length: #{detailed.length}"

# Replace inside html
file_path = './online_viewer.html'
html = File.read(file_path)

start_marker = "const boundingCoordinates = "
start_idx = html.index(start_marker)
if start_idx
  start_idx += start_marker.length
  end_idx = html.index(";", start_idx)
  
  new_array_string = JSON.generate(detailed)
  new_html = html[0...start_idx] + new_array_string + html[end_idx..-1]
  File.write(file_path, new_html)
  puts "HTML Coordinates fixed!"
end
