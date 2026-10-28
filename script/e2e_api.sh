#!/usr/bin/env bash
# Prueba de punta a punta de la API real (y del back-office) con curl.
#
# Requisitos: servidor corriendo (bin/rails server) con los seeds cargados (bin/rails db:seed).
# Uso:        script/e2e_api.sh [URL_BASE]      (por defecto http://localhost:3000)
#
# Guarda cada respuesta en tmp/api_examples/<nombre>.json (se usan como ejemplos reales en docs/api).
# Termina con código 1 si algún chequeo falla.

set -u
BASE="${1:-http://localhost:3000}"
API="$BASE/api/v1"
OUT="tmp/api_examples"
mkdir -p "$OUT"
PASS=0
FAIL=0

# json <archivo> <expresión ruby sobre j>  → imprime el valor
json() { ruby -rjson -e 'j = JSON.parse(File.read(ARGV[0])); v = eval(ARGV[1]); puts(v.is_a?(String) ? v : v.to_json)' "$1" "$2"; }

# call <nombre> <status esperado> <método> <ruta> [token] [cuerpo JSON]
call() {
  local name="$1" expected="$2" method="$3" path="$4" token="${5:-}" body="${6:-}"
  local args=(-s -o "$OUT/$name.json" -w "%{http_code}" -X "$method" "$API$path" -H "Accept: application/json")
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  # El cuerpo va por archivo: en Windows curl.exe recodifica los argumentos y rompe los acentos.
  if [ -n "$body" ]; then
    printf '%s' "$body" > "$OUT/.body.json"
    args+=(-H "Content-Type: application/json; charset=utf-8" --data-binary "@$OUT/.body.json")
  fi
  local status
  status=$(curl "${args[@]}")
  printf '%s %s %s\n' "$method" "$path" "$body" > "$OUT/$name.request.txt"
  if [ "$status" = "$expected" ]; then
    PASS=$((PASS + 1)); printf '  OK    %-38s %s %s → %s\n' "$name" "$method" "$path" "$status"
  else
    FAIL=$((FAIL + 1)); printf '  FALLA %-38s %s %s → %s (esperado %s)\n' "$name" "$method" "$path" "$status" "$expected"
    head -c 400 "$OUT/$name.json"; echo
  fi
}

check() { # check <descripción> <condición ruby que debe dar true> <archivo>
  if [ "$(json "$3" "$2")" = "true" ]; then PASS=$((PASS + 1)); echo "  OK    $1"; else FAIL=$((FAIL + 1)); echo "  FALLA $1"; fi
}

echo "== Autenticación"
call login_ok 200 POST /login "" '{"email_address":"empleado@farma-check.com","password":"demo1234"}'
EMP=$(json "$OUT/login_ok.json" 'j["token"]')
call login_admin 200 POST /login "" '{"email_address":"admin@farma-check.com","password":"demo1234"}'
ADMIN=$(json "$OUT/login_admin.json" 'j["token"]')
call login_wrong_password 401 POST /login "" '{"email_address":"empleado@farma-check.com","password":"incorrecta"}'
call login_missing_fields 422 POST /login "" '{}'
call profile 200 GET /profile "$EMP"
call profile_no_token 401 GET /profile
call profile_bad_token 401 GET /profile "token-inexistente"

echo "== Dashboard"
call dashboard 200 GET /dashboard "$EMP"

echo "== Productos"
call products_search 200 GET "/products?search=ibuprofeno&per_page=2" "$EMP"
call products_low_stock 200 GET "/products?stock_status=stock_bajo&per_page=2" "$EMP"
call products_invalid_filter 422 GET "/products?stock_status=mucho" "$EMP"
PRODUCT_ID=$(json "$OUT/products_search.json" 'j["data"].find { |p| p["name"] == "Ibuprofeno 400 mg" }["id"]')
call product_show 200 GET "/products/$PRODUCT_ID" "$EMP"
call product_not_found 404 GET "/products/999999" "$EMP"

echo "== Lotes"
call batches_critical 200 GET "/batches?expiration_status=critico&per_page=2" "$EMP"
call batches_invalid_filter 422 GET "/batches?expiration_status=podrido" "$EMP"
BATCH_ID=$(json "$OUT/product_show.json" 'j["data"]["batches"].find { |b| b["expiration_status"] == "ok" }["id"]')
call batches_expired 200 GET "/batches?expiration_status=vencido&per_page=1" "$EMP"
EXPIRED_ID=$(json "$OUT/batches_expired.json" 'j["data"][0]["id"]')
call batch_show 200 GET "/batches/$BATCH_ID" "$EMP"
STOCK_BEFORE=$(json "$OUT/batch_show.json" 'j["data"]["quantity"]')

echo "== Movimientos"
call movement_create 201 POST /stock_movements "$EMP" "{\"stock_movement\":{\"batch_id\":$BATCH_ID,\"movement_type\":\"salida\",\"quantity\":2,\"reason\":\"Venta en mostrador\"}}"
check "la salida descuenta 2 unidades del lote" "j['data']['batch']['quantity'] == $STOCK_BEFORE - 2" "$OUT/movement_create.json"
call movement_insufficient_stock 422 POST /stock_movements "$EMP" "{\"stock_movement\":{\"batch_id\":$BATCH_ID,\"movement_type\":\"salida\",\"quantity\":100000}}"
call movement_invalid_type 422 POST /stock_movements "$EMP" "{\"stock_movement\":{\"batch_id\":$BATCH_ID,\"movement_type\":\"entry\",\"quantity\":5}}"
call movement_expired_batch 422 POST /stock_movements "$EMP" "{\"stock_movement\":{\"batch_id\":$EXPIRED_ID,\"movement_type\":\"salida\",\"quantity\":1}}"
call movement_missing_batch 400 POST /stock_movements "$EMP" '{"stock_movement":{"movement_type":"salida","quantity":1}}'
call movements_list 200 GET "/stock_movements?movement_type=salida&per_page=2" "$EMP"
call movements_invalid_date 422 GET "/stock_movements?from=28/10/2026" "$EMP"
call batch_after_movement 200 GET "/batches/$BATCH_ID" "$EMP"
check "el lote quedó con el stock actualizado (sin cambios por los rechazados)" "j['data']['quantity'] == $STOCK_BEFORE - 2" "$OUT/batch_after_movement.json"

echo "== Proveedores"
call suppliers_list 200 GET "/suppliers?per_page=2" "$EMP"
SUPPLIER_ID=$(json "$OUT/suppliers_list.json" 'j["data"][0]["id"]')
call supplier_show 200 GET "/suppliers/$SUPPLIER_ID" "$EMP"
CUIT=$(ruby -e 'loop { d = "30" + format("%08d", rand(10**8)); s = d.chars.map(&:to_i).zip([5,4,3,2,7,6,5,4,3,2]).sum { |a, b| a * b }; r = 11 - s % 11; r = 0 if r == 11; next if r == 10; puts "#{d[0,2]}-#{d[2,8]}-#{r}"; break }')
call supplier_create_forbidden 403 POST /suppliers "$EMP" "{\"supplier\":{\"company_name\":\"Droguería Demo S.A.\",\"cuit\":\"$CUIT\"}}"
call supplier_create 201 POST /suppliers "$ADMIN" "{\"supplier\":{\"company_name\":\"Droguería Demo S.A.\",\"cuit\":\"$CUIT\",\"email\":\"ventas@demo.com.ar\",\"phone\":\"011 4000-1234\",\"contact_name\":\"Ana Pérez\"}}"
NEW_SUPPLIER=$(json "$OUT/supplier_create.json" 'j["data"]["id"]')
call supplier_invalid_cuit 422 POST /suppliers "$ADMIN" '{"supplier":{"company_name":"CUIT malo S.A.","cuit":"30-12345678-9"}}'
call supplier_update 200 PATCH "/suppliers/$NEW_SUPPLIER" "$ADMIN" '{"supplier":{"phone":"011 4999-0000"}}'

echo "== Órdenes de compra"
call orders_list 200 GET "/purchase_orders?status=sent&per_page=2" "$EMP"
call orders_invalid_status 422 GET "/purchase_orders?status=perdida" "$EMP"
call order_create 201 POST /purchase_orders "$EMP" "{\"purchase_order\":{\"supplier_id\":$SUPPLIER_ID,\"notes\":\"Reposición semanal\",\"items\":[{\"product_id\":$PRODUCT_ID,\"quantity\":24,\"unit_price\":1450.5}]}}"
ORDER_ID=$(json "$OUT/order_create.json" 'j["data"]["id"]')
ITEM_ID=$(json "$OUT/order_create.json" 'j["data"]["items"][0]["id"]')
check "el total lo calcula el servidor (24 × 1450,50 = 34812)" "j['data']['total_amount'] == 34812.0" "$OUT/order_create.json"
call order_create_invalid 422 POST /purchase_orders "$EMP" "{\"purchase_order\":{\"supplier_id\":$SUPPLIER_ID,\"items\":[]}}"
call order_show 200 GET "/purchase_orders/$ORDER_ID" "$EMP"
call order_receive_pending 422 POST "/purchase_orders/$ORDER_ID/receive" "$EMP" "{\"purchase_order\":{\"items\":[]}}"
call order_send 200 PATCH "/purchase_orders/$ORDER_ID/send" "$EMP"
call order_send_again 422 PATCH "/purchase_orders/$ORDER_ID/send" "$EMP"
call order_cancel_forbidden 403 PATCH "/purchase_orders/$ORDER_ID/cancel" "$EMP"
call order_receive_invalid 422 POST "/purchase_orders/$ORDER_ID/receive" "$EMP" "{\"purchase_order\":{\"items\":[{\"id\":$ITEM_ID,\"lot_number\":\"\",\"expiration_date\":\"2020-01-01\"}]}}"
LOT="DEMO-$(date +%s)"
NEXT_YEAR=$(( $(date +%Y) + 1 ))
call product_before_receive 200 GET "/products/$PRODUCT_ID" "$EMP"
TOTAL_BEFORE=$(json "$OUT/product_before_receive.json" 'j["data"]["total_stock"]')
call order_receive 200 POST "/purchase_orders/$ORDER_ID/receive" "$EMP" "{\"purchase_order\":{\"items\":[{\"id\":$ITEM_ID,\"lot_number\":\"$LOT\",\"expiration_date\":\"$NEXT_YEAR-03-31\",\"location\":\"Depósito\"}]}}"
call product_after_receive 200 GET "/products/$PRODUCT_ID" "$EMP"
check "la recepción creó el lote $LOT" "j['data']['batches'].any? { |b| b['lot_number'] == '$LOT' && b['quantity'] == 24 }" "$OUT/product_after_receive.json"
check "el stock total subió 24 unidades" "j['data']['total_stock'] == $TOTAL_BEFORE + 24" "$OUT/product_after_receive.json"
call order_cancel_received 422 PATCH "/purchase_orders/$ORDER_ID/cancel" "$ADMIN"
call order_create_to_cancel 201 POST /purchase_orders "$EMP" "{\"purchase_order\":{\"supplier_id\":$SUPPLIER_ID,\"items\":[{\"product_id\":$PRODUCT_ID,\"quantity\":1,\"unit_price\":10}]}}"
CANCEL_ID=$(json "$OUT/order_create_to_cancel.json" 'j["data"]["id"]')
call order_cancel 200 PATCH "/purchase_orders/$CANCEL_ID/cancel" "$ADMIN"
call order_not_found 404 GET "/purchase_orders/999999" "$EMP"

echo "== Cierre de sesión"
call logout 200 DELETE /logout "$EMP"
call profile_after_logout 401 GET /profile "$EMP"
call logout_without_token 401 DELETE /logout

echo "== CORS (preflight desde el front-end)"
CORS=$(curl -s -i -X OPTIONS "$API/products" -H "Origin: http://localhost:5173" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: authorization" | tr -d '\r' | grep -i '^access-control-allow-origin:')
if [ "$CORS" = "access-control-allow-origin: http://localhost:5173" ]; then PASS=$((PASS + 1)); echo "  OK    CORS permite http://localhost:5173"; else FAIL=$((FAIL + 1)); echo "  FALLA CORS: '$CORS'"; fi

echo "== Back-office (sesión por cookie)"
JAR=$(mktemp)
code=$(curl -s -o /dev/null -w "%{http_code}" -c "$JAR" "$BASE/session/new")
TOKEN=$(curl -s -b "$JAR" -c "$JAR" "$BASE/session/new" | grep -o 'name="authenticity_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"$//')
login=$(curl -s -o /dev/null -w "%{http_code}" -b "$JAR" -c "$JAR" -X POST "$BASE/session" \
  --data-urlencode "authenticity_token=$TOKEN" --data-urlencode "email_address=admin@farma-check.com" --data-urlencode "password=demo1234")
for page in /dashboard /products /batches /stock_movements /suppliers /purchase_orders; do
  status=$(curl -s -o /dev/null -w "%{http_code}" -b "$JAR" "$BASE$page")
  if [ "$status" = "200" ]; then PASS=$((PASS + 1)); echo "  OK    back-office $page → 200"; else FAIL=$((FAIL + 1)); echo "  FALLA back-office $page → $status"; fi
done
[ "$code" = "200" ] && [ "$login" = "302" ] && { PASS=$((PASS + 1)); echo "  OK    login del back-office (302)"; } || { FAIL=$((FAIL + 1)); echo "  FALLA login del back-office ($code / $login)"; }
rm -f "$JAR"

echo
echo "Resultado: $PASS OK, $FAIL fallas. Respuestas guardadas en $OUT/"
[ "$FAIL" -eq 0 ]
