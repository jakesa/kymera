#This extends the array class to add copy functionality.
class Array
  def copy_to(array)
    self.map {|t| array << t}
    array
  end

  def copy
    self.map {|t| t}
  end
end