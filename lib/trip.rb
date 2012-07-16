class Trip
  def initialize(opts = {})
    @origin      = opts.fetch(:origin)      { raise ArgumentError.new("origin is required") }
    @destination = opts.fetch(:destination) { raise ArgumentError.new("destination is required") }
    @mode        = opts.fetch(:mode)        { 'driving' }
  end

  def distance
    response[:distance]
  end

  def duration
    response[:duration]
  end

  def cost
    response[:cost]
  end

  private
  def response
    return @response if @response

    data      = MapsAPI.get(:origin => @origin.content, :destination => @destination.content, :mode => @mode)
    first_leg = MapsAPI.first_leg(data)
    
    @response = {
      :distance => first_leg['distance']['value'],
      :duration => first_leg['duration']['value'],
    }
  end
end