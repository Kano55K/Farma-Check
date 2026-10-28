class SupplierSerializer < BaseSerializer
  def as_json
    {
      id: object.id,
      company_name: object.company_name,
      cuit: object.cuit,
      email: object.email,
      phone: object.phone,
      contact_name: object.contact_name,
      created_at: timestamp(object.created_at),
      updated_at: timestamp(object.updated_at)
    }
  end
end
