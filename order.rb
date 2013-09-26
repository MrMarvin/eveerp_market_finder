class Order
  attr_accessor :region, :station, :station_name, :price, :vol_remain, :expires

  def initialize(region, station, station_name, price, vol_remain, expires)
    self.region = region
    self.station = station
    self.station_name = station_name
    self.price = price
    self.vol_remain = vol_remain
    self.expires = expires
  end
  
end