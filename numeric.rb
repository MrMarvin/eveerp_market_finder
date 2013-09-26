# thanks Maarten! http://markmail.org/message/hjc7mwfrfwwhf64i

class Numeric

  def format(separator = ',', decimal_point = '.')
    num_parts = self.to_s.split('.')
    x = num_parts[0].reverse.scan(/.{1,3}/).join(separator).reverse
    x << decimal_point + num_parts[1] if num_parts.length == 2
    x
  end

  def Numeric.format(number, *args) 
    number.format(*args) 
  end

end