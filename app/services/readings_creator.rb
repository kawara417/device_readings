class ReadingsCreator
  def initialize(params)
    @params = params
  end

  def create
    successful = []
    failed = []
    @params[:readings].each do |r|
      reading = Reading.new(timestamp: r[:timestamp], count: r[:count].to_i)
      reading_json = reading.as_json
      if reading.valid?
        reading.add_reading(@params[:id])
        successful << reading_json
      else
        failed << reading_json.merge({ errors: reading.errors })
      end
    end
    { successful: successful, failed: failed }
  end
end
