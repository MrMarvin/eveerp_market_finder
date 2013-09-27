module EveCentral
  
  NUM_THREADS=5
  
  class <<self
    def look_up(list_of_type_ids)
      puts "#{Time.now} | EveCentral::look_up (#{list_of_type_ids.size} types)"
      @lookups = []
      while not list_of_type_ids.empty?
        ids = list_of_type_ids.slice!(0..NUM_THREADS)
        ids.map { |id| Thread.new { @lookups << EveCentral::Lookup.new(id) } }.each(&:join)
      end
      @lookups
    end
  end

  class Lookup
     
    attr_reader :itemname, :typeId, :stations

    def initialize(typeId)

      @typeId = typeId.to_i
     
      regions = [
           10000002, # the Forge / Jita
           10000043, # Domain / Amarr
           10000032 # Sinq Lisason / Dodi
       ]
       @stations = {
           60003760 => Market.new(60003760,"Jita IV - Moon 4 - Caldari Navy Assembly Plant"),
           60011866 => Market.new(60011866,"Dodixie IX - Moon 20 - Federation Navy Assembly Plant"), 
           60008494 => Market.new(60008494,"Amarr VIII (Oris) - Emperor Family Academy")
       }

       link = "http://api.eve-central.com/api/quicklook?typeid=#{typeId}&sethours=24&#{(regions.collect { |reg| "regionlimit=#{reg}&" }).join}"
       #puts "requesting: #{link}"
       doc = Nokogiri::XML.parse(open(link).read)

       @itemname = doc.xpath("//itemname").text

       doc.xpath("//sell_orders/order").each do |order|
         if @stations.keys.include?(order.xpath("station").text.to_i)
           @stations[order.xpath("station").text.to_i].sells << Order.new(order.xpath("region").text.to_i,
                                                                  order.xpath("station").text.to_i,
                                                                  order.xpath("station_name").text,
                                                                  order.xpath("price").text.to_f,
                                                                  order.xpath("vol_remain").text.to_i,
                                                                  order.xpath("expires").text)
         end
       end
       doc.xpath("//buy_orders/order").each do |order|
         if @stations.keys.include?(order.xpath("station").text.to_i)
           @stations[order.xpath("station").text.to_i].buys << Order.new(order.xpath("region").text.to_i,
                                                                     order.xpath("station").text.to_i,
                                                                     order.xpath("station_name").text,
                                                                     order.xpath("price").text.to_f,
                                                                     order.xpath("vol_remain").text.to_i,
                                                                     order.xpath("expires").text)
         end
       end

       @stations.keys.each do |station|
         @stations[station].sort!
       end
   end

 end
end