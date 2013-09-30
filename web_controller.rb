require "evestatic"
include Evestatic

require "./numeric"
require "./order"
require "./market"
require "./lookup"
require "./evecentral"
require "./evemarketdata"
require 'nokogiri'
require 'open-uri'
require 'sinatra'


module Parser
  def type_ids_from_paste(paste)
    ids = []
    paste.split("\r\n").each do |line|
      splitted = line.split("\t")
      #puts splitted.inspect
      #puts splitted.size
      if splitted.size < 7
        # paste from inventory
        name = splitted[0]
      else
        # paste from wallet transactions
        name = splitted[1]
      end
      #puts "#{name} detected"
      begin
        ids << ItemType.by_name(name.gsub(/\ +$/,"")).type_id
      rescue NameError
        puts "no typeID found for: #{name}! Misspelled?"
      end
    end
    ids
  end
end

module MarketHelpers
  def style_for_split(split,percent,greatest)
    if split >= greatest
      "color: green; font-size: 90%; font-weight: bold;"
    elsif split >= percent
      "color: lightgreen; font-size: 90%;"
    else
      "color: grey; font-size: 90%;"
    end
  end
end

helpers Parser, MarketHelpers

get "/" do
  @lookups = []
  if params["typeId"].nil? and params["name"].nil? and params["paste"].nil?
    erb :index
  else
    if params["typeId"]
      types = [params["typeId"]]
    elsif params["name"]
      types = [ItemType[params["name"]].type_id]
    elsif params["paste"]      
      types = type_ids_from_paste(params["paste"])
    end
      #@lookups = EveCentral::look_up(types)
      @lookups  = ItemLookup.new(types).items
    erb :list
  end

end
