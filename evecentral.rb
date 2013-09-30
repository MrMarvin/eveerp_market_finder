require 'digest/sha1'

module EveCentral

  
  NUM_THREADS=10
  CACHE_TIME=10*60 # 600 seconds = 10 mins
  
  class <<self
    def look_up(list_of_type_ids,regions,stations)
      puts "#{Time.now} | EveCentral::look_up (#{list_of_type_ids.size} types)"
      @lookups = []
      list_of_type_ids = list_of_type_ids.uniq
      while not list_of_type_ids.empty?
        ids = list_of_type_ids.slice!(0..NUM_THREADS)
        # doing a deep copy by marshalling here. Otherwise the threads will break stuff badly!
        ids.map { |id| Thread.new { @lookups << EveCentral::Lookup.new(id,regions.dup,Marshal.load( Marshal.dump(stations))) } }.each(&:join)
      end
      @lookups
    end
  end

  class Lookup
    
    attr_reader :itemname, :type_id, :stations

    def initialize(type_id,regions,stations)

      @type_id = type_id.to_i
     
     
      @stations = stations 
       #puts "#{Time.now} | EveCentral::Lookup for #{@type_id} in #{regions.join(" ")}"
       link = "http://api.eve-central.com/api/quicklook?type_id=#{@type_id}&sethours=24&#{(regions.collect { |reg| "regionlimit=#{reg}&" }).join}"
       if $cache
         thread_safe_cache = $cache.clone
         begin
           # using sha1 here to shorten the link, sometimes i does not fit into mongos max key length
           res = thread_safe_cache.get(Digest::SHA1.hexdigest(link))
           puts "#{Time.now} | EveCentral | found #{@type_id} in cache"
         rescue Memcached::NotFound
           res = open(link).read
           thread_safe_cache.set(Digest::SHA1.hexdigest(link), res, CACHE_TIME)
           puts "#{Time.now} | EveCentral | stored #{@type_id} in cache"
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
                                                                  order.xpath("price").text.to_f,
                                                                  order.xpath("vol_remain").text.to_i,
                                                                  order.xpath("expires").text)
         end
       end
       doc.xpath("//buy_orders/order").each do |order|
         if @stations.keys.include?(order.xpath("station").text.to_i)
           @stations[order.xpath("station").text.to_i].buys << Order.new(order.xpath("region").text.to_i,
                                                                     order.xpath("station").text.to_i,
                                                                     order.xpath("price").text.to_f,
                                                                     order.xpath("vol_remain").text.to_i,
                                                                     order.xpath("expires").text)
         end
       end

       @stations.keys.each do |station_id|
         @stations[station_id].sort!
       end
   end

 end
end