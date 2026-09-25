User.find_or_create_by!(email_address: "admin@farma-stock.com") do |u|
  u.password = "kanolo_55"
  u.password_confirmation = "kanolo_55"
  u.role = :admin
end

puts "Usuario creado: admin@farma-stock.com / kanolo_55"
