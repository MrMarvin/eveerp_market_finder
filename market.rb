class Market
  attr_accessor :station, :station_name, :sells, :buys

  def initialize(station)
    @station = station
    @sells = []
    @buys = []
  end
  
  def sort!
    @sells.sort_by! {|order| order.price }
    @buys.sort_by! {|order| -order.price }
  end
  
  def split(top=10)
    self.avg_sell_price(top) / self.avg_buy_price(top)
  end
  
  def split_percent(top=10)
    diff = self.avg_sell_price(top) - self.avg_buy_price(top)
    ((diff / self.avg_sell_price(top))*100).round(1)
  end

  def avg_sell_price(top=0)
    self.sort!
    @sells[0..top-1].inject(0.0) {|sum, order| sum+order.price } / ((top != 0 and top < @sells.size) ? top : @sells.size)
  end
  
  def avg_buy_price(top=0)
    self.sort!
    @buys[0..top-1].inject(0.0) {|sum, order| sum+order.price } / ((top != 0 and top < @buys.size) ? top : @buys.size)
  end
  
  def remote_split(remote_market,top=10)
    remote_market.avg_sell_price(top) / self.avg_buy_price(top)
  end
  
  def remote_split_percent(remote_market,top=10)
    diff = remote_market.avg_sell_price(top) - self.avg_buy_price(top)
    ((diff / remote_market.avg_sell_price(top))*100).round(1)
  end
  
  def greatest_remote_split_percent(remote_markets,top=10)
    biggest_known = 0.0
    remote_markets.each do |market|
      new_split = remote_split_percent(market,top)
      #puts "calculation split for #{@station.station_name.split(" - ")[0]} #{market.station.station_name.split(" - ")[0]}: #{new_split}"
      biggest_known = biggest_known > new_split ? biggest_known : new_split
    end
    biggest_known
  end
  
  def self.greatest_split_percent(markets,top=10)
    biggest_known = 0.0
    markets.each do |market|
      # note: markets include market, so local split will be included in remote splits
      new_split = market.greatest_remote_split_percent(markets,top)
      biggest_known = biggest_known > new_split ? biggest_known : new_split
    end
    biggest_known
  end
  
end