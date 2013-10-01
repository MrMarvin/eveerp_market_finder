require 'json'
require 'digest/sha1'
NAME_AKA_USERAGENT = "Nivram Mei says: thank you for running this service!".gsub(" ","%20")

module EveMarketdata

  class TypeMarket

    CACHE_TIME=10*60 # 10 minutes

    def self.look_up(list_of_type_ids, station_hash)
      lookups = []
      puts "#{Time.now} | #{self}::look_up (#{list_of_type_ids.size} types)"
      type_hash_station_hash = parse_api_res_to_objects(request_from_api(list_of_type_ids.uniq, station_hash),station_hash)
      type_hash_station_hash.each_pair { |type_id,stations_hash| lookups << self.new(type_id,stations_hash) }
      lookups
    end

    def self.request_from_api(type_ids, station_hash)
      region_ids = station_hash.keys.collect {|station| Station.by_id(station).region_id }
      link = "http://api.eve-marketdata.com/api/item_orders2.xml?char_name=#{NAME_AKA_USERAGENT}&buysell=a&type_ids=#{type_ids.join(",")}&station_ids=#{station_hash.keys.join(",")}"
      res = store_to_cache(link,open(link).read) unless res = check_cache(link)
      res
    end

    def self.check_cache(link)
      if $cache
        thread_safe_cache = $cache.clone
        begin
          # using sha1 here to shorten the link, sometimes i does not fit into mongos max key length
          res = thread_safe_cache.get(Digest::SHA1.hexdigest(link))
          puts "#{Time.now} | #{self} | found in cache"
        rescue Memcached::NotFound
          false
        end
        res
      end
    end

    def self.store_to_cache(link,res)
      if $cache
        $cache.clone.set(Digest::SHA1.hexdigest(link), res, CACHE_TIME)
        puts "#{Time.now} | #{self} | stored in cache"
      end
      res
    end

    def self.parse_api_res_to_objects(res,station_hash)
      type_hash_station_hash = {} #temp hash to store each type and its station_hash
      doc = Nokogiri::XML.parse(res)
      doc.xpath("//row").each do |row|
        type_id = row.attribute("typeID").text.to_i
        station_id = row.attribute("stationID").text.to_i

        # making a deep copy of the station_hash for each type
        type_hash_station_hash[type_id] = Marshal.load( Marshal.dump(station_hash)) unless type_hash_station_hash[type_id]

        new_order = Order.new(row.attribute("regionID").text.to_i,
                             station_id,
                             row.attribute("price").text.to_f,
                             row.attribute("volRemaining").text.to_i,
                             row.attribute("expires").text)

        if row.attribute("buysell").text == "s"
          type_hash_station_hash[type_id][station_id].sells << new_order
        else
          type_hash_station_hash[type_id][station_id].buys << new_order
        end
      end
      type_hash_station_hash
    end

    attr_reader :itemname, :type_id, :stations
    def initialize(type_id,station_hash)
      @stations = station_hash
      @type_id = type_id
      @itemname = ItemType.by_id(type_id).type_name
    end


  end

  class History

    CACHE_TIME=60*60 # one hour

    def self.mass_lookup(type_ids,region_ids)
      types = {}
      type_ids.each {|t_id| types[t_id] = {}}      
      link = "http://api.eve-marketdata.com/api/item_history2.json?char_name=#{NAME_AKA_USERAGENT}&region_ids=#{region_ids.join(",")}&type_ids=#{type_ids.join(",")}"
      if $cache
        thread_safe_cache = $cache.clone
        begin
          # using sha1 here to shorten the link, sometimes i does not fit into mongos max key length
          res = thread_safe_cache.get(Digest::SHA1.hexdigest(link))
          puts "#{Time.now} | #{self} | found #{type_ids.join(",")} in cache"
        rescue Memcached::NotFound
          res = open(link).read
          thread_safe_cache.set(Digest::SHA1.hexdigest(link), res, CACHE_TIME)
          puts "#{Time.now} | #{self} | stored #{type_ids.join(",")} in cache"
        end
        h = JSON.parse(res)
      else
        # fallback for no cache at all:
        h = JSON.parse(open(link).read)
      end      
      h["emd"]["result"].each do |result|
        row = result["row"]
        # make sure we have an object for this type and region
        types[row["typeID"].to_i][row["regionID"].to_i] = self.new(row["typeID"].to_i,row["regionID"].to_i) unless types[row["typeID"].to_i][row["regionID"].to_i] 
        # store the new day in it:
        types[row["typeID"].to_i][row["regionID"].to_i].days << [row["date"],row["orders"].to_i,row["volume"].to_i,row["lowPrice"].to_f,row["highPrice"].to_f,row["avgPrice"].to_f]
      end
      types
    end

    attr_reader :type_id, :region_id, :days
    
    def initialize(type_id,region_id)
      @type_id = type_id
      @region_id = region_id
      @days = []
    end

    def days_with_values
      @days.collect { |d| d[0] }
    end

    def last_n_days(n)
      n = (n < @days.size ? n : @days.size)
      (@days.sort_by {|d| d[0]})[-n..-1]
    end

    def last_day
      last_n_days(1)
    end

    def avg(n=0)
      last_days = last_n_days(n)
      sum_of_last_days = last_days.inject([0,0,0,0,0]) {|(orders,vol,min,max,avg),d| [orders+d[1],vol+d[2],min+d[3],max+d[4],avg+d[5]]}
      [last_days.size].concat(sum_of_last_days.map {|value| (value / last_days.size).round(2) })
    end

  end
end