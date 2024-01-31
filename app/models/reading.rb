class Reading
  include ActiveModel::Validations

  attr_reader :timestamp, :count

  validates :timestamp, presence: true
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  validate :valid_timestamp

  @@mutex = Mutex.new

  def initialize(attributes = {})
    @timestamp = attributes[:timestamp]
    @count = attributes[:count]
  end

  def add_reading(device_id)
    @@mutex.synchronize do
      device_reading = Rails.cache.fetch("device_#{device_id}")
      break if device_reading.present? && device_reading['timestamps'].has_key?(timestamp_in_utc)

      device_reading = {
        'timestamps' => {},
        'latest_timestamp' => timestamp_in_utc,
        'cumulative_count' => 0
      } if device_reading.nil?

      device_reading['timestamps'][timestamp_in_utc] = @count
      device_reading['cumulative_count'] += @count
      device_reading['latest_timestamp'] = timestamp_in_utc if timestamp_in_utc > device_reading['latest_timestamp']

      Rails.cache.write("device_#{device_id}", device_reading)
    end
  end

  private

  def valid_timestamp
    DateTime.parse(@timestamp) rescue errors.add(:timestamp, 'is not a valid timestamp')
  end

  def timestamp_in_utc
    @timestamp_in_utc ||= Time.zone.parse(@timestamp).utc.to_s
  end
end
