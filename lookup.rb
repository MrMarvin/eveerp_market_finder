module EveCentral

  begin
    require 'memcached'
    $cache = Memcached.new("localhost:11211")
    $cache.set_prefix_key(self.to_s+"_")
    $cache.set("test","works! :-)")
    $cache.get("test") 
  rescue LoadError
    puts "#{Time.now} | EveCentral | could not load memcached -> NO CACHING SUPPORT!"
  rescue Memcached::ServerIsMarkedDead
    puts "#{Time.now} | EveCentral | could not connect to memcached -> NO CACHING SUPPORT!"
    $cache = nil
  end
  
  NUM_THREADS=10
  CACHE_TIME=10*60 # 600 seconds = 10 mins
  
  class <<self
    def look_up(list_of_type_ids)
      puts "#{Time.now} | EveCentral::look_up (#{list_of_type_ids.size} types)"
      @lookups = []
      list_of_type_ids = list_of_type_ids.uniq
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
           MapRegion.by_name("The Forge").region_id, # Jita
           MapRegion.by_name("Domain").region_id, # Amarr
           MapRegion.by_name("Sinq Laison").region_id # Dodi
       ]
       @stations = {
           Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant").station_id => Market.new(Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant")),
           Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant").station_id => Market.new(Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant")), 
           Station.by_name("Amarr VIII (Oris) - Emperor Family Academy").station_id => Market.new(Station.by_name("Amarr VIII (Oris) - Emperor Family Academy"))
       }
       
       #puts "#{Time.now} | EveCentral::Lookup for #{@typeId} in #{regions.join(" ")}"
       link = "http://api.eve-central.com/api/quicklook?typeid=#{typeId}&sethours=24&#{(regions.collect { |reg| "regionlimit=#{reg}&" }).join}"
       if $cache
         thread_safe_cache = $cache.clone
         begin
           res = thread_safe_cache.get(link)
           puts "#{Time.now} | EveCentral | found #{@typeId} in cache"
         rescue Memcached::NotFound
           res = open(link).read
           thread_safe_cache.set(link, res, CACHE_TIME)
           puts "#{Time.now} | EveCentral | stored #{@typeId} in cache"
         end
         doc = Nokogiri::XML.parse(res)
       else
         # fallback for no cache at all:
         doc = Nokogiri::XML.parse(open(link).read)
       end

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