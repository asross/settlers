class CatanError < StandardError; end

class Catan
  def error(msg)
    raise CatanError, msg
  end
end
