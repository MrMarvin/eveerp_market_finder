require "./itemtype.rb"
require "./order.rb"
require 'nokogiri'
require 'open-uri'
require 'sinatra'


get "/" do
  if params["typeId"].nil? and params["name"].nil?
    return "please specify either: typeId=42 or name=Tritanium (make sure to type the whole name!) .\n
    Example: \t/?typeId=34 \n
    \t /?name=Expanded Cargohold II\n"
  elsif params["name"]
    params["typeId"] = ItemType[params["name"]].type_id
  end

  threads = []
  regions = [
      10000002, # the Forge / Jita
      10000043, # Domain / Amarr
      10000032 # Sinq Lisason / Dodi
  ]
  @stations = {
      60003760 => [], # Jita IV - Moon 4 - Caldari Navy Assembly Plant
      60011866 => [], # Dodixie IX - Moon 20 - Federation Navy Assembly Plant
      60008494 => [] # Amarr VIII (Oris) - Emperor Family Academy
  }
  link = "http://api.eve-central.com/api/quicklook?typeid=#{params["typeId"]}&sethours=24&#{(regions.collect { |reg| "regionlimit=#{reg}&" }).join}"
  puts "requesting: #{link}"
  doc = Nokogiri::XML.parse(open(link).read)

  @itemname = doc.xpath("//itemname").text
  @typeid = params["typeId"].to_i

  doc.xpath("//sell_orders/order").each do |order|
    if @stations.keys.include?(order.xpath("station").text.to_i)
      @stations[order.xpath("station").text.to_i] << Order.new(order.xpath("region").text.to_i,
                                                             order.xpath("station").text.to_i,
                                                             order.xpath("station_name").text,
                                                             order.xpath("price").text.to_f,
                                                             order.xpath("vol_remain").text.to_i,
                                                             order.xpath("expires").text)
    end
  end
  @stations.keys.each do |station|
    @stations[station].sort_by! {|order| order.price }
  end
  erb :list

end
