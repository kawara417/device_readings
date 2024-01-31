class Device
  include ActiveModel::Validations

  attr_reader :id
  validate :valid_id

  def initialize(attributes = {})
    @id = attributes[:id]
  end

  private

  def valid_id
    # TODO: if we are certain of id format, we should run validations here
  end
end
