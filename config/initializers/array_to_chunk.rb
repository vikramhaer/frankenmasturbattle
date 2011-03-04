class Array
  # breaks an array into smaller arrays of size n returns an array of smaller arrays of size n or less.
  def chunk(n)
    len = self.length
    rtn = []
    (0..len/n).each do |i|
      rtn << self[i*n..(i+1)*n-1]
    end
    if len%n == 0 then
      rtn[0..-2]
    else
      rtn
    end
  end
end

