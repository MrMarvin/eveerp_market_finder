class ItemLookup

  attr_reader :items
           
  def initialize(types,regions=nil,stations=nil)
    @types = types
    @regions = regions || [
         MapRegion.by_name("The Forge").region_id, # Jita
         MapRegion.by_name("Domain").region_id, # Amarr
         MapRegion.by_name("Sinq Laison").region_id # Dodi
     ]
    @stations = stations ||  {
          Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant").station_id => Market.new(Station.by_name("Jita IV - Moon 4 - Caldari Navy Assembly Plant")),
          Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant").station_id => Market.new(Station.by_name("Dodixie IX - Moon 20 - Federation Navy Assembly Plant")), 
          Station.by_name("Amarr VIII (Oris) - Emperor Family Academy").station_id => Market.new(Station.by_name("Amarr VIII (Oris) - Emperor Family Academy"))}
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