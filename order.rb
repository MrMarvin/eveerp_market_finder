class Order
  attr_accessor :region, :station, :price, :vol_remain, :expires

  def initialize(region_id, station_id, price, vol_remain, expires)
    self.region = region_id
    self.station = station_id
    self.price = price
    self.vol_remain = vol_remain
    self.expires = expires
  end

  def station_name
    Station.by_id(station_id).station_name
  end
  
end