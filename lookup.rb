class ItemLookup

  begin
    require 'memcached'
    $cache = Memcached.new("localhost:11211")
    $cache.set_prefix_key(self.to_s+"_")
    $cache.set("test","works! :-)")
    $cache.get("test") 
  rescue LoadError
    puts "#{Time.now} | #{self} | could not load memcached -> NO CACHING SUPPORT!"
  rescue Memcached::ServerIsMarkedDead
    puts "#{Time.now} | #{self} | could not connect to memcached -> NO CACHING SUPPORT!"
    $cache = nil
  end

  attr_reader :items
           
  def initialize(types,stations=nil)
    @types = types

    @stations = stations ||  {
          Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant").station_id => Market.new(Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant")),
          Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant").station_id => Market.new(Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant")), 
          Station.by_name("Hek VIII - Moon 12 - Boundless Creation Factory").station_id => Market.new(Station.by_name("Hek VIII - Moon 12 - Boundless Creation Factory"))
          }
          
    @regions = @stations.keys.collect {|station| Station.by_id(station).region_id }
                
    price_lookup!
    history_lookup!
  end
  
  def price_lookup!
     @items = EveCentral::look_up(@types,@regions,@stations)
  end
  
  def history_lookup!
    price_lookup! unless @items
    histories = EveMarketdata::History.mass_lookup(@types,@regions)
    @items.each do |item|
      item.stations.each_value do |market|
        market.history = histories[item.type_id][market.station.region_id]
      end      
    end
  end
end