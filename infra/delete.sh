  set -e
  read -rp "Zadejte název funkce (např. HelloLambda): " FUNCTION_NAME
  if [ -z "${FUNCTION_NAME}" ]; then
    echo "Chyba: název funkce je povinný." >&2
    usage
fi

ENDPOINT_URL="http://localhost:4566"

aws lambda delete-function \
  --function-name "${FUNCTION_NAME}" \
  --endpoint-url "${ENDPOINT_URL}"
