class Model
  def initialize(params={})
    # Fill in the object with the provided parameters
    params.each do |name, value|
      writer = "#{name}="
      send writer, value if respond_to? writer
    end
  end
end
