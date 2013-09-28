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
    ((split(top)-1.0)*100).round(1)
  end

  def avg_sell_price(top=0)
    self.sort!
    @sells[0..top-1].inject(0.0) {|sum, order| sum+order.price } / ((top != 0 and top < @sells.size) ? top : @sells.size)
  end
  
  def avg_buy_price(top=0)
    self.sort!
    @buys[0..top-1].inject(0.0) {|sum, order| sum+order.price } / ((top != 0 and top < @buys.size) ? top : @buys.size)
  end
  
end