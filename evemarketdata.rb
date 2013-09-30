require 'json'
NAME_AKA_USERAGENT = "Nivram Mei says: thank you for running this service!".gsub(" ","%20")

module EveMarketdata

  class History

    def self.mass_lookup(type_ids,region_ids)
      types = {}
      type_ids.each {|t_id| types[t_id] = {}}
      link = "http://api.eve-marketdata.com/api/item_history2.json?char_name=#{NAME_AKA_USERAGENT}&region_ids=#{region_ids.join(",")}&type_ids=#{type_ids.join(",")}"
      h = JSON.parse(open(link).read)
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