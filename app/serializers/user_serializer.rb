class UserSerializer < BaseSerializer
  def as_json
    {
      id: object.id,
      email: object.email_address,
      role: object.role
    }
  end
end
