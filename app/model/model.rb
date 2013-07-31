class Model
  def initialize(params={})
    # Fill in the object with the provided parameters
    params.each do |name, value|
      if name == :date && !value.respond_to?(:strftime)
        # Turn whatever this is into a date
        value = Time.zone.parse(value)
      end
      writer = "#{name}="
      send writer, value if respond_to? writer
    end
  end
end
