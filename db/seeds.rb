# Datos de demostración de Farma-Check. Idempotente: correrlo varias veces no duplica nada.
#
#   bin/rails db:seed
#
# Usuarios (contraseña de demo para todos: demo1234):
#   admin@farma-check.com     (admin)
#   empleado@farma-check.com  (employee)
#   farmaceutica@farma-check.com (employee)
#
# Las fechas de vencimiento se calculan respecto de la fecha en que se corren los seeds,
# así el semáforo siempre muestra lotes vencidos, críticos (< 30 días), en alerta (< 90 días) y ok.

DEMO_PASSWORD = "demo1234".freeze
today = Date.current

# --- Usuarios -------------------------------------------------------------------------------
users = {
  admin: { email: "admin@farma-check.com", role: :admin },
  empleado: { email: "empleado@farma-check.com", role: :employee },
  farmaceutica: { email: "farmaceutica@farma-check.com", role: :employee }
}.transform_values do |data|
  User.find_or_create_by!(email_address: data[:email]) do |u|
    u.password = DEMO_PASSWORD
    u.password_confirmation = DEMO_PASSWORD
    u.role = data[:role]
  end
end

# --- Proveedores (CUIT con dígito verificador válido) -----------------------------------------
suppliers = [
  { company_name: "Droguería del Sur S.A.", cuit: "30-71234567-1", email: "ventas@drogueriadelsur.com.ar", phone: "011 4555-1234", contact_name: "Marta Gómez" },
  { company_name: "Distribuidora Pampa S.R.L.", cuit: "30-70987654-2", email: "pedidos@pampa.com.ar", phone: "0221 422-9876", contact_name: "Jorge Ruiz" },
  { company_name: "Droguería Norte S.A.", cuit: "30-70111222-5", email: "info@drognorte.com.ar", phone: "0381 430-1122", contact_name: "Lucía Fernández" },
  { company_name: "Farmacéutica Cuyo S.A.", cuit: "30-71888999-1", email: "compras@farmacuyo.com.ar", phone: "0261 425-3344", contact_name: "Pablo Sosa" },
  { company_name: "Monroe Distribuciones S.A.", cuit: "30-58122334-6", email: "atencion@monroedist.com.ar", phone: "011 4302-5566", contact_name: "Carolina Díaz" }
].map do |attrs|
  Supplier.find_or_initialize_by(cuit: attrs[:cuit]).tap { |s| s.update!(attrs) }
end

# --- Productos -------------------------------------------------------------------------------
# min_stock define el umbral de "stock bajo". Los lotes se describen como
# [número de lote, días hasta el vencimiento (negativo = vencido), cantidad, ubicación].
catalog = [
  { name: "Ibuprofeno 400 mg", active_ingredient: "Ibuprofeno", laboratory: "Bagó", presentation: "Comprimidos x 20", therapeutic_action: "Analgésico / antiinflamatorio", prescription_required: false, min_stock: 30,
    batches: [ [ "IBU-2401", 420, 120, "Góndola 1 - A" ], [ "IBU-2312", 20, 25, "Góndola 1 - A" ] ] },
  { name: "Paracetamol 500 mg", active_ingredient: "Paracetamol", laboratory: "Elea", presentation: "Comprimidos x 16", therapeutic_action: "Analgésico / antipirético", prescription_required: false, min_stock: 40,
    batches: [ [ "PAR-2405", 540, 200, "Góndola 1 - B" ] ] },
  { name: "Amoxicilina 500 mg", active_ingredient: "Amoxicilina", laboratory: "Roemmers", presentation: "Cápsulas x 16", therapeutic_action: "Antibiótico", prescription_required: true, min_stock: 25,
    batches: [ [ "AMX-2402", 60, 18, "Mostrador - Cajón 3" ], [ "AMX-2311", -15, 6, "Mostrador - Cajón 3" ] ] },
  { name: "Enalapril 10 mg", active_ingredient: "Enalapril", laboratory: "Gador", presentation: "Comprimidos x 30", therapeutic_action: "Antihipertensivo", prescription_required: true, min_stock: 20,
    batches: [ [ "ENA-2403", 365, 80, "Estante B - 2" ] ] },
  { name: "Losartán 50 mg", active_ingredient: "Losartán potásico", laboratory: "Roemmers", presentation: "Comprimidos x 30", therapeutic_action: "Antihipertensivo", prescription_required: true, min_stock: 20,
    batches: [ [ "LOS-2404", 25, 40, "Estante B - 2" ] ] },
  { name: "Atorvastatina 20 mg", active_ingredient: "Atorvastatina", laboratory: "Baliarda", presentation: "Comprimidos x 30", therapeutic_action: "Hipolipemiante", prescription_required: true, min_stock: 15,
    batches: [ [ "ATV-2401", 75, 12, "Estante B - 3" ] ] },
  { name: "Omeprazol 20 mg", active_ingredient: "Omeprazol", laboratory: "Gador", presentation: "Cápsulas x 28", therapeutic_action: "Protector gástrico", prescription_required: false, min_stock: 30,
    batches: [ [ "OME-2406", 600, 150, "Góndola 2 - A" ] ] },
  { name: "Metformina 850 mg", active_ingredient: "Metformina", laboratory: "Montpellier", presentation: "Comprimidos x 60", therapeutic_action: "Antidiabético", prescription_required: true, min_stock: 20,
    batches: [ [ "MET-2402", 200, 45, "Estante C - 1" ] ] },
  { name: "Levotiroxina 50 mcg", active_ingredient: "Levotiroxina sódica", laboratory: "Montpellier", presentation: "Comprimidos x 50", therapeutic_action: "Hormona tiroidea", prescription_required: true, min_stock: 10,
    batches: [ [ "LEV-2403", 300, 0, "Estante C - 1" ] ] },
  { name: "Salbutamol aerosol 100 mcg", active_ingredient: "Salbutamol", laboratory: "Casasco", presentation: "Aerosol x 200 dosis", therapeutic_action: "Broncodilatador", prescription_required: true, min_stock: 10,
    batches: [ [ "SAL-2401", 150, 22, "Mostrador - Cajón 1" ] ] },
  { name: "Loratadina 10 mg", active_ingredient: "Loratadina", laboratory: "Raffo", presentation: "Comprimidos x 10", therapeutic_action: "Antialérgico", prescription_required: false, min_stock: 20,
    batches: [ [ "LOR-2405", 45, 30, "Góndola 2 - B" ] ] },
  { name: "Diclofenac 75 mg", active_ingredient: "Diclofenac sódico", laboratory: "Bagó", presentation: "Comprimidos x 15", therapeutic_action: "Antiinflamatorio", prescription_required: false, min_stock: 20,
    batches: [ [ "DIC-2402", 10, 14, "Góndola 1 - C" ], [ "DIC-2404", 280, 60, "Góndola 1 - C" ] ] },
  { name: "Clonazepam 0,5 mg", active_ingredient: "Clonazepam", laboratory: "Roemmers", presentation: "Comprimidos x 30", therapeutic_action: "Ansiolítico", prescription_required: true, min_stock: 10,
    batches: [ [ "CLO-2403", 400, 35, "Psicotrópicos - Caja fuerte" ] ] },
  { name: "Amoxicilina + ácido clavulánico 875/125 mg", active_ingredient: "Amoxicilina / ácido clavulánico", laboratory: "Elea", presentation: "Comprimidos x 14", therapeutic_action: "Antibiótico", prescription_required: true, min_stock: 15,
    batches: [ [ "AMC-2402", -40, 8, "Mostrador - Cajón 3" ] ] },
  { name: "Azitromicina 500 mg", active_ingredient: "Azitromicina", laboratory: "Baliarda", presentation: "Comprimidos x 3", therapeutic_action: "Antibiótico", prescription_required: true, min_stock: 10,
    batches: [ [ "AZI-2404", 85, 16, "Mostrador - Cajón 3" ] ] },
  { name: "Ranitidina 150 mg", active_ingredient: "Ranitidina", laboratory: "Raffo", presentation: "Comprimidos x 20", therapeutic_action: "Protector gástrico", prescription_required: false, min_stock: 10,
    batches: [] },
  { name: "Ibuprofeno pediátrico 2% jarabe", active_ingredient: "Ibuprofeno", laboratory: "Bagó", presentation: "Suspensión x 90 ml", therapeutic_action: "Analgésico / antipirético", prescription_required: false, min_stock: 15,
    batches: [ [ "IBP-2405", 5, 9, "Góndola 3 - A" ], [ "IBP-2407", 190, 30, "Góndola 3 - A" ] ] },
  { name: "Dexametasona 4 mg", active_ingredient: "Dexametasona", laboratory: "Sidus", presentation: "Comprimidos x 10", therapeutic_action: "Corticoide", prescription_required: true, min_stock: 10,
    batches: [ [ "DEX-2403", 230, 25, "Estante D - 1" ] ] },
  { name: "Insulina NPH 100 UI/ml", active_ingredient: "Insulina humana isofánica", laboratory: "Laboratorios Beta", presentation: "Frasco ampolla x 10 ml", therapeutic_action: "Antidiabético", prescription_required: true, min_stock: 8,
    batches: [ [ "INS-2404", 70, 5, "Heladera" ] ] },
  { name: "Sertralina 50 mg", active_ingredient: "Sertralina", laboratory: "Gador", presentation: "Comprimidos x 30", therapeutic_action: "Antidepresivo", prescription_required: true, min_stock: 10,
    batches: [ [ "SER-2402", 330, 40, "Estante D - 2" ] ] },
  { name: "Aspirina 100 mg", active_ingredient: "Ácido acetilsalicílico", laboratory: "Bayer", presentation: "Comprimidos x 28", therapeutic_action: "Antiagregante plaquetario", prescription_required: false, min_stock: 25,
    batches: [ [ "ASP-2406", 480, 90, "Góndola 1 - D" ] ] },
  { name: "Bisoprolol 5 mg", active_ingredient: "Bisoprolol", laboratory: "Baliarda", presentation: "Comprimidos x 30", therapeutic_action: "Antihipertensivo", prescription_required: true, min_stock: 15,
    batches: [ [ "BIS-2401", -5, 10, "Estante B - 3" ], [ "BIS-2405", 260, 8, "Estante B - 3" ] ] },
  { name: "Cetirizina 10 mg", active_ingredient: "Cetirizina", laboratory: "Casasco", presentation: "Comprimidos x 10", therapeutic_action: "Antialérgico", prescription_required: false, min_stock: 15,
    batches: [ [ "CET-2404", 120, 50, "Góndola 2 - B" ] ] },
  { name: "Budesonide spray nasal 64 mcg", active_ingredient: "Budesonide", laboratory: "Elea", presentation: "Spray x 120 dosis", therapeutic_action: "Corticoide nasal", prescription_required: true, min_stock: 6,
    batches: [ [ "BUD-2403", 28, 7, "Mostrador - Cajón 2" ] ] },
  { name: "Simeticona 80 mg", active_ingredient: "Simeticona", laboratory: "Montpellier", presentation: "Comprimidos masticables x 30", therapeutic_action: "Antiflatulento", prescription_required: false, min_stock: 10,
    batches: [ [ "SIM-2405", 400, 45, "Góndola 2 - C" ] ] }
]

products = {}
catalog.each_with_index do |data, index|
  barcode = format("779%010d", 100_000 + index)
  product = Product.find_or_initialize_by(barcode: barcode)
  product.update!(
    data.except(:batches).merge(
      code: data[:name].split.first.upcase.first(3) + format("%03d", index + 1),
      safety_stock: (data[:min_stock] / 2.0).ceil,
      gondola_location: data[:batches].first&.last
    )
  )
  products[data[:name]] = product

  data[:batches].each do |lot_number, days, quantity, location|
    batch = product.batches.find_or_initialize_by(lot_number: lot_number)
    next unless batch.new_record? # no se pisa el stock de un lote que ya existe

    batch.update!(expiration_date: today + days, quantity: quantity, location: location, status: :active)

    # Historial coherente con el stock: una entrada inicial y algunas salidas.
    # Se insertan sin callbacks porque el stock del lote ya quedó en su valor final.
    sales = quantity.zero? ? [ 4, 3 ] : [ (quantity * 0.2).ceil, (quantity * 0.1).ceil ]
    received_at = (today - 60).in_time_zone.change(hour: 9)
    rows = [ { movement_type: StockMovement.movement_types[:entrada], quantity: quantity + sales.sum, reason: "Ingreso inicial (seed)",
               user_id: users[:admin].id, created_at: received_at } ]
    sales.each_with_index do |sold, i|
      rows << { movement_type: StockMovement.movement_types[:salida], quantity: sold, reason: "Venta en mostrador",
                user_id: users[i.even? ? :empleado : :farmaceutica].id, created_at: received_at + (10 * (i + 1)).days + (index % 6).hours }
    end
    StockMovement.insert_all(rows.map { |row| row.merge(batch_id: batch.id, updated_at: row[:created_at]) })
  end
end

# --- Órdenes de compra -----------------------------------------------------------------------
# Se identifican por la nota (prefijo [seed-oc-N]) para no duplicarlas.
orders = [
  { key: "seed-oc-1", supplier: suppliers[0], status: :pending, notes: "Reposición de analgésicos",
    items: [ [ "Ibuprofeno 400 mg", 100, 1450.00 ], [ "Paracetamol 500 mg", 120, 980.50 ] ] },
  { key: "seed-oc-2", supplier: suppliers[1], status: :sent, notes: "Antibióticos y antihipertensivos",
    items: [ [ "Amoxicilina 500 mg", 60, 3200.00 ], [ "Losartán 50 mg", 40, 2750.00 ] ] },
  { key: "seed-oc-3", supplier: suppliers[2], status: :sent, notes: "Pedido urgente de insulina",
    items: [ [ "Insulina NPH 100 UI/ml", 20, 18500.00 ] ] },
  { key: "seed-oc-4", supplier: suppliers[3], status: :received, notes: "Compra mensual de crónicos",
    items: [ [ "Enalapril 10 mg", 80, 1890.00 ], [ "Metformina 850 mg", 50, 2100.00 ] ] },
  { key: "seed-oc-5", supplier: suppliers[4], status: :cancelled, notes: "Cancelada por precio",
    items: [ [ "Ranitidina 150 mg", 30, 1200.00 ] ] }
]

orders.each do |data|
  notes = "[#{data[:key]}] #{data[:notes]}"
  next if PurchaseOrder.exists?(notes: notes)

  order = PurchaseOrder.new(supplier: data[:supplier], status: data[:status], notes: notes)
  data[:items].each do |name, quantity, price|
    order.purchase_order_items.build(product: products.fetch(name), quantity: quantity, unit_price: price)
  end
  order.save!
end

puts "Seeds cargados:"
puts "  Usuarios: #{User.count} | Proveedores: #{Supplier.count} | Productos: #{Product.count}"
puts "  Lotes: #{Batch.count} | Movimientos: #{StockMovement.count} | Órdenes de compra: #{PurchaseOrder.count}"
puts "  Credenciales de demo (contraseña #{DEMO_PASSWORD}):"
users.each_value { |u| puts "    #{u.email_address} (#{u.role})" }
