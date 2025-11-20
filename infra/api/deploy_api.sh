#!/bin/bash
set -e

# Využívá LocalStack (endpoint) a vytvoří API Gateway REST API s non-proxy Lambda integrací,
# která pošle do Lambdy jen JSON tělo (ne celý API Gateway proxy event).
# To umožní ponechat tvůj původní handler (RequestHandler<Map<String,String>,...>).
#
# Použití:
#   chmod +x apigw_create_nonproxy_with_request_template.sh
#   ./apigw_create_nonproxy_with_request_template.sh

REGION="eu-central-1"
ENDPOINT="http://localhost:4566"
LAMBDA_NAME="testovaciFunkce"

echo "🔧 Creating API Gateway REST API..."

API_ID=$(aws apigateway create-rest-api \
  --name "LocalHelloAPI" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT" \
  --query 'id' --output text)

echo "✅ API created: $API_ID"

echo "🔧 Getting root resource ID..."
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id "$API_ID" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT" \
  --query 'items[0].id' --output text)

echo "ROOT_ID = $ROOT_ID"

echo "🔧 Creating /hello resource..."
HELLO_ID=$(aws apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part hello \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT" \
  --query 'id' --output text)

echo "HELLO_ID = $HELLO_ID"

echo "🔧 Adding POST method to /hello..."

aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$HELLO_ID" \
  --http-method POST \
  --authorization-type NONE \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT"

echo "🔧 Integrating POST with Lambda (non-proxy) and adding request template so Lambda receives only client body..."

# Request template: převezme přes HTTP tělo klienta (JSON) a pošle ho jako payload do Lambda.
# Pokud klient pošle {"name":"pavel"} -> Lambda obdrží mapu s klíčem "name".
REQUEST_TEMPLATES='{"application/json":"$input.body"}'

aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$HELLO_ID" \
  --http-method POST \
  --type AWS \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:000000000000:function:$LAMBDA_NAME/invocations" \
  --request-templates "$REQUEST_TEMPLATES" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT"

echo "🔧 Creating Method Response (200)..."

aws apigateway put-method-response \
  --rest-api-id "$API_ID" \
  --resource-id "$HELLO_ID" \
  --http-method POST \
  --status-code 200 \
  --response-models '{"application/json":"Empty"}' \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT"

echo "🔧 Creating Integration Response -> Method Response mapping (status 200) (default mapping)..."

# Default integration response (bez selection-pattern) - matchne vše a přeposílá tělo tak, jak ho Lambda vrátí.
INTEGRATION_RESPONSE_TEMPLATES='{"application/json":"$input.body"}'

aws apigateway put-integration-response \
  --rest-api-id "$API_ID" \
  --resource-id "$HELLO_ID" \
  --http-method POST \
  --status-code 200 \
  --response-templates "$INTEGRATION_RESPONSE_TEMPLATES" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT"

echo "🔧 Allowing API Gateway to invoke Lambda (restricted source-arn)..."

aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id apigw-test-$RANDOM \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:000000000000:$API_ID/*/POST/hello" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT" \
  || true

echo "🔧 Deploying API to stage: prod..."

aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT" \
  >/dev/null

echo ""
echo "🎉 API successfully deployed!"
echo "🌍 Your POST endpoint (non-proxy -> Lambda dostane jen body klienta):"
echo "http://localhost:4566/_aws/execute-api/$API_ID/prod/hello"
echo ""