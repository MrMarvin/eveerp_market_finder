require 'CSV'

class ItemType

  attr_accessor :type_id, :group_id, :type_name, :mass, :volume

  @@item_types = {}

  def self.load_from_file(path)
    begin
      CSV.foreach(path, {col_sep: ";", headers: true}) do |row|
        @@item_types[row[2]] = self.new(row[0].to_i, row[1].to_i, row[2], row[3].to_i, row[4].gsub(",",".").to_f)
      end
    rescue CSV::MalformedCSVError
      #trololol do nothing, we have all data, dont care if the newlines are windows mess or whatever
    end
  end

  def self.[](key=nil)
    unless key
      @@item_types
    else
      @@item_types[key]
    end
  end

  def initialize(type_id, group_id, type_name, mass, volume)
    self.type_id = type_id
    self.group_id = group_id
    self.type_name = type_name
    self.mass = mass
    self.volume = volume
  end
end

ItemType.load_from_file "invTypes.csv"