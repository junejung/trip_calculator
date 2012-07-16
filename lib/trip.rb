class Trip
  def initialize(opts = {})
    @origin      = opts.fetch(:origin)      { raise ArgumentError.new("origin is required") }
    @destination = opts.fetch(:destination) { raise ArgumentError.new("destination is required") }
    @mode        = opts.fetch(:mode)        { 'driving' }
  end

  def valid?
    data['status'] == 'OK'
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

    @response = {
      :distance => first_leg['distance']['value'],
      :duration => first_leg['duration']['value'],
    }
  end

  def data
    @data ||= MapsAPI.get(:origin => @origin.content, :destination => @destination.content, :mode => @mode)
  end

  def first_leg
    MapsAPI.first_leg(data)
  end
end