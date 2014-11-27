class DeepOpenStruct
  def initialize(hash)
    hash.each { |k, v| define_singleton_method(k) {
      instance_variable_get(:"@#{k}") || instance_variable_set(:"@#{k}", coerce(v))
    } }
  end

  def [](k)
    send(k)
  end

  def coerce(v)
    case v
    when Hash then DeepOpenStruct.new(v)
    when Array then v.map(&method(:coerce))
    else v
    end
  end
end
