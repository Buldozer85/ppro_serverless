# PRPO Serverless

Workshop demonstrující serverless architekturu s využitím AWS CLI a LocalStack pro lokální vývoj.

Tento workshop Vás provede základy serveless vývoje s využitím dockerizované služby LocalStack, která je vhodná pro bezplatné testování běhěm vývoje. Pro komunikaci bude sloužit AWS CLI.

## Co se naučíte?

- Vytvořit a nahrát serveless funkci
- Napojení na API Gateway
- Ukládání dat do DynamoDB
- Základy AWS CLI

## Technologie

- **Kotlin** - programovací jazyk pro Lambda funkce
- **Gradle** - build nástroj a správa závislostí
- **AWS Lambda** - serverless compute služba
- **LocalStack** - lokální AWS cloud stack pro vývoj a testování
- **Docker** - kontejnerizace LocalStack prostředí
- **AWS CLI** - nástroj pro práci s AWS službami

## Požadavky
- Na windows WSL
- JDK 11+
- Docker Desktop
- AWS CLI v2
- Gradle 8+ (nebo použij wrapper `./gradlew`)

## Instalace
### AWS CLI

#### Linux
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### MacOS
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### Windows
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```
Nebo stáhněte msi z https://awscli.amazonaws.com/AWSCLIV2.msi


### Inicializace 
Jelikož k localstacku nejsou potřeba žádné údaje, stačí vyplnit následovně:

- Access key ID: test
- Secret access key: test
- Default region name: eu-central-1
- Default output format: json

#### MAC + LINUX
```bash
aws configure
```

#### Windows
```powershell
aws configure
```
## Struktura projektu

```
prpo_serverless/
├── lambda/
│   ├── src/
│   │   ├── main/
│   │   │   └── kotlin/
│   │   │       └── example/
│   │   │           └── Handler.kt
│   ├── build/
│   │   └── libs/
│   │       └── funkce.jar 
│   ├── build.gradle.kts
├── localstack_data/
├── docker-compose.yml
├── build.gradle.kts
├── settings.gradle.kts
└── README.md
```

## Lokální vývoj
Využití docker-compose 

```yaml
version: "3.9"

services:
  localstack:
    container_name: localstack
    image: localstack/localstack:stable
    ports:
      - "4566:4566"     # hlavní endpoint
      - "4571:4571"
    environment:
      - SERVICES=lambda,apigateway,dynamodb,cloudwatch,logs,s3
      - DEBUG=1
      - LAMBDA_EXECUTOR=docker
      - AWS_DEFAULT_REGION=eu-central-1
      - DOCKER_HOST=unix:///var/run/docker.sock
      - LOCALSTACK_API_KEY=${LOCALSTACK_API_KEY-}   # prázdné = Free version
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./localstack_data:/var/lib/localstack"
      - "./lambda/build/libs:/opt/lambda"        # Destinace .jar balíčků
```

### Spuštění LocalStack

```bash
docker compose up -d
```
### Endpoint
http://localhost:4566/

### AWS CLI basic příkazy
```bash
aws lambda create-function # Vytvoření lambda funkce
aws lambda delete-function # Smazání funkce
aws lambda list-functions # Výpis funkcí
aws lambda invoke --function-name nazev_funkce --payload # Zavolání funkce a předání payloadu
```

## Krok za krokem

### Úkol 1: Vytvořte v souboru Handle funkci a nahrajte ji na LocalStack.  
Doplňte funkci handleRequest v jazyku Kotlin tak, že:

1. přijme JSON objekt { "name": "Alice" }
2. vrátí "Hello, Alice"
3. loguje čas spuštění

Následně vytvořte její build a nahrajte do AWS Lambda.
Pro nahrání využijte AWS CLI se skriptem v složce infra

#### Řešení
##### Krok 1 Handler.kt
```Kotlin
class Handler : RequestHandler<Map<String, String>, String> {
    override fun handleRequest(input: Map<String, String>, context: Context): String {
        val name = input["name"] ?: "Unknown"
        return "Hello, $name! (LocalStack Kotlin Lambda)"
    }
}

```
##### Krok 2 Build

```bash
  cd lambda
  ./gradlew build
```

##### Krok 3 Nahrání do LocalStack
```bash
  cd ..
  ./infra/deploy.sh # Lze předat název funkce
  # Pro ukončení výpisu stačí zmáčknout klávesu q
  #alternativně
  aws lambda create-function \
  --function-name <FUNCTION_NAME> #název funkce 
  --runtime java17 \
  --handler example.Handler #třída s metodou handleRequest 
  --zip-file fileb://<JAR> #zkompilovaný jar soubor
  --role arn:aws:iam::000000000000:role/lambda-role #role 
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  
```

##### Test, že se vytvořila funkce 
```bash
  ./infra/test.sh # Lze předat název funkce
  # Pro ukončení výpisu stačí zmáčknout klávesu q
  #alternativně 
  aws lambda list-functions \
  --endpoint-url http://localhost:4566
```

##### Odeslání dat
```bash
  aws lambda invoke \
  --function-name testovaciFunkce \
  --payload '{"name":"Pavel"}' \
  --cli-binary-format raw-in-base64-out \
  --endpoint-url http://localhost:4566 \
  response.json
```



### Úkol 2 Vytvoření API gateway
#### Co je API Gateway?
AWS API Gateway je plně spravovaná služba pro vytváření, publikování, zabezpečení, monitorování a verzování REST, HTTP a WebSocket API. Slouží jako vstupní bod (gateway) pro klienty, směruje požadavky na backend (např. AWS Lambda, HTTP služby), řeší autorizaci, throttling, cachování, transformace requestů/response a poskytuje metriky a logování přes CloudWatch. Umožňuje oddělit prezentaci API od implementace a škálovat bez správy infrastruktury.

#### Základní příkazy
```bash
aws apigateway create-rest-api           # Vytvoří novou definici REST API (název, ID)
aws apigateway get-resources             # Vypíše strom dostupných resources (cesty) API
aws apigateway create-resource           # Přidá novou resource (cestu) pod parent ID
aws apigateway put-method                # Definuje HTTP metodu (GET/POST...) na resource
aws apigateway put-integration           # Napojí metodu na backend (Lambda/HTTP/Mock)
aws apigateway put-method-response       # Definuje odpověď metody (status kód, hlavičky, model)
aws apigateway put-integration-response  # Mapuje odpověď backendu na odpověď metody
aws lambda add-permission                # Umožní API Gateway volat danou Lambda funkci
aws apigateway create-deployment         # Nasadí API konfiguraci na zvolenou stage
```

#### Krok za krokem

Vše je zautomatizováno ve sciptu /infra/api/deploy_api.sh'

##### Krok 1 Vytvoření API
Důležité si uchovat ID API pro další kroky. Alternativně lze vypsat znovu příkazem.
```bash
#Vytvoření API s názvem LocalHelloAPI
API_ID=$(aws apigateway create-rest-api \
  --name "LocalHelloAPI" \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  --query 'id' --output text)
```
Vypsání informací o všech vytvořených API
```bash
aws apigateway get-rest-apis \
--endpoint-url http://localhost:4566 \
--output table
```

##### Krok 2 Získání Root resource ID
- Root resource reprezentuje adresář "/"
- V rámci API je stromová hierarchie, kde nastavení parenta znamená přiřazení pod daný resource. Například resource /home je přiřažený pod root resource, kdežto resource /home/about má parent_id již resource /home místo root resource a je pod tento /home taktéž přiřazen.
```bash
ROOT_ID=$(aws apigateway get-resources \
--rest-api-id <API_ID> \
--region "eu-central-1" \
--endpoint-url "http://localhost:4566" \
--query 'items[0].id' --output text)
```

##### Krok 3 Vytvoření nového resource
Vytvoříme si resource /hello. Během vytváření specifikujeme parent_id jako root resource ID a api ID, aby bylo jasné, ve které API se to má vytvořit.
Získáme ID resource, které je důležité pro další kroky.
```bash
HELLO_ID=$(aws apigateway create-resource \
  --rest-api-id <API_ID> \
  --parent-id <ROOT_ID> \
  --path-part hello \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  --query 'id' --output text)
```
##### Krok 4 Přiřazení POST HTTP metody resource
Tímto krokem nabindujeme resource /hello na metodu POST.
```bash
aws apigateway put-method \
  --rest-api-id <API_ID> \
  --resource-id <HELLO_ID> \
  --http-method POST \
  --authorization-type NONE \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566"
```

##### Krok 5 Vytvoření non-proxy AWS integrace s Lamda funkcí
```bash
aws apigateway put-integration \
  --rest-api-id <API_ID> \
  --resource-id <HELLO_ID> \
  --http-method POST \
  --type AWS \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:000000000000:function:<FUNCTION_NAME>/invocations" \
  --request-templates '{"application/json":"$input.body"}' # Specifikace co má přijímat Lambda funkce
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566"
```

##### Krok 6 Deklarace metody response API gatewayu
```bash
aws apigateway put-method-response \
  --rest-api-id <API_ID> \
  --resource-id <HELLO_ID> \
  --http-method POST \
  --status-code 200 \
  --response-models '{"application/json":"Empty"}' \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566"
```

##### Krok 7 Deklarace integrace response API gatewayu
```bash
aws apigateway put-integration-response \
  --rest-api-id <API_ID> \
  --resource-id <HELLO_ID> \
  --http-method POST \
  --status-code 200 \
  --response-templates '{"application/json":"$input.body"}' \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566"
```

##### Krok 8 Nastavení oprávnění invoknout lambda funkci
```bash
aws lambda add-permission \
  --function-name <FUNCTION_NAME> \
  --statement-id apigw-test-$RANDOM \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:000000000000:$API_ID/*/POST/hello" \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  || true
```

##### Krok 9 Deploy na prostředí
```bash
aws apigateway create-deployment \
  --rest-api-id <API_ID> \
  --stage-name prod \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  >/dev/null
```

##### Krok 10 Test
Je více možností testování
1. Postman
2. Curl

**Postman**
Pro testování přes postman je třeba mít nainstalovaný a spuštěný Postman agent

- Do url se vloží http://localhost:4566/_aws/execute-api/<API_ID>/prod/<RESOURCE_NAME>
- Vybere se metoda POST
- do Headers se vloží Content-Type: application/json 
- do body raw JSON {"name": "pavel"}

**curl**
```bash
 curl -X POST \     
  http://localhost:4566/restapis/<API_ID>/prod/_user_request_/<RESOURCE_NAME> \
  -H "Content-Type: application/json" \
  -d '{"name":"Pavel"}'
```