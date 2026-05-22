require 'net/http'
require 'json'
require 'uri'

def fetch_intersection(s1, s2)
  query = %Q(
    [out:json];
    area["name:zh"="九龍"]->.a;
    way["name:zh"~"#{s1}"](area.a)->.w1;
    way["name:zh"~"#{s2}"](area.a)->.w2;
    node(w.w1)(w.w2);
    out geom;
  )
  uri = URI('https://overpass-api.de/api/interpreter')
  req = Net::HTTP::Post.new(uri)
  req.body = query
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  data = JSON.parse(res.body)
  if data['elements'].any?
    return [data['elements'][0]['lon'], data['elements'][0]['lat']]
  else
    return nil
  end
end

pt1 = fetch_intersection("渡船街", "塘尾道")
pt2 = fetch_intersection("塘尾道", "櫻桃街")
puts "Intersection 渡船街 & 塘尾道: #{pt1.inspect}"
puts "Intersection 塘尾道 & 櫻桃街: #{pt2.inspect}"
