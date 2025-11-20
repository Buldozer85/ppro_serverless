set -e
JAR=lambda/build/libs/ppro_serverless.jar
REGION=eu-central-1
ENDPOINT=http://localhost:4566
DEFAULT_FUNCTION_NAME="ppro_serverless"
read -rp "Zadejte název funkce [${DEFAULT_FUNCTION_NAME}]: " _input
FUNCTION_NAME="${_input:-$DEFAULT_FUNCTION_NAME}"

aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime java17 \
  --handler example.Handler \
  --zip-file fileb://$JAR \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --region $REGION \
  --endpoint-url $ENDPOINT \
  || \
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://$JAR \
  --region $REGION \
  --endpoint-url $ENDPOINT

echo "Hotovo."
exit 0