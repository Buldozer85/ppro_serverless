# PRPO Serverless

Workshop demonstrující serverless architekturu s využitím AWS CLI a LocalStack pro lokální vývoj.

Tento workshop Vás provede základy serveless vývoje s využitím dockerizované služby LocalStack, která je vhodná pro bezplatné testování běhěm vývoje. Pro komunikaci bude sloužit AWS CLI.

## Teoretický přehled
Serverless je způsob vývoje a provozu aplikací, kdy vývojář nemusí spravovat servery.
Nemusí se řešit:
- infrastruktura
- provisioning
- škálování
- aktualizace OS 
- kapacity

To vše dělá cloud provider (AWS, Azure, GCP).

Vy jen nahrajete funkci nebo službu — a cloud ji spustí, když je potřeba.

### Jak serverless funguje?

1. Napíše se malý kus kódu (např. funkce v Kotlinu).
2. Nasadí se do cloudu (AWS Lambda).
3. Kód se spouští na vyžádání, např.:
    - HTTP požadavek (API Gateway)
    - změna v databázi (DynamoDB Stream)
    - cron job (EventBridge)
    - nahrání souboru (S3)
4. Pokud není žádný provoz → funkce neběží → neplatí se nic.

### Klíčové služby v serverless architektuře
1) AWS Lambda (core)
    - Spouští funkce napsané v Kotlinu, Java, Python, Nodeu… 
    - Běží jen při requestu. 
    - Účtování za počet volání + dobu běhu.
2) API Gateway
   - Spravuje HTTP API. 
   - Route → Lambda. 
   - Autorizace, throttling, transformace JSON.
3) DynamoDB
   - Serverless NoSQL databáze. 
   - Škáluje automaticky. 
   - Platí se jen za skutečné R/W operace.
4) EventBridge
   - Cron, eventová komunikace, event-driven architektura.
5) S3
   - Triggery na nahrání souborů. 
   - Hostování statických webů.

### Výhody 

- Bez nutnosti spravovat infrastrukturu
- Platí se pouze za provoz
- Automatické škálování
- Rychlý vývoj
- Mikroservisní architektura

### Na co je vhodná serveless

- Api endpointy, cron joby, webhooky, light backend služby, datové zpracování ETL operace

### Na co se nehodí

- Dlouhé výpočty, nízko-latenční realtime služby, aplikace, které vyžadují persistentní procesy, masivní batch processing (pak raději ECS/EKS)

### Nevýhody serverless
❌ Cold start - První spuštění po delší pauze je pomalejší (Java/Kotlin více než Node/Python).

❌ Omezené runtime prostředí
- Čas běhu max. 15 minut
- Omezený filesystem
- Komunikace v rámci VPC musí být správně nastavena

❌ Vendor lock-in - Počítá se s AWS ekosystémem.

## Co se naučíte?

- Vytvořit a nahrát serveless funkci
- Napojení na API Gateway
- Základy AWS CLI
- Volitelně ukládání dat do DynamoDB

## Technologie

- **Kotlin** - programovací jazyk pro Lambda funkce
- **Gradle** - build nástroj a správa závislostí
- **AWS Lambda** - serverless compute služba
- **LocalStack** - lokální AWS cloud stack pro vývoj a testování
- **Docker** - kontejnerizace LocalStack prostředí
- **AWS CLI** - nástroj pro práci s AWS službami

## Požadavky
- Na windows WSL
- JDK 17
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
    ├── settings.gradle.kts
├── localstack_data/
├── docker-compose.yml
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
Potřeba této závislosti (již doplněná v build.gradle.kts):

```kotlin
implementation("com.amazonaws:aws-lambda-java-core:1.2.1")
```

Doplňte funkci handleRequest v jazyku Kotlin tak, že:

1. přijme JSON objekt { "name": "Alice" }
2. vrátí "Hello, Alice"
3. loguje čas spuštění

Následně vytvořte její build a nahrajte do AWS Lambda.
Pro nahrání využijte AWS CLI se skriptem v složce infra

#### Řešení
##### Krok 1 Handler.kt
```Kotlin
class Handler : RequestHandler<Map<String, String>, Map<String, String>> {
    override fun handleRequest(input: Map<String, String>, context: Context): Map<String, String> {
        val name = input["name"] ?: "Unknown"
        return mapOf("message" to "Hello, $name!")
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
  --function-name <FUNCTION_NAME> \
  --runtime java17 \
  --handler example.Handler \ 
  --zip-file fileb://<JAR> \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" 
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

Vše je zautomatizováno ve sciptu ./infra/api/deploy_api.sh'
```bash
  ./infra/api/deploy_api.sh
```

##### Krok 1 Vytvoření API
Důležité si uchovat ID API pro další kroky. Alternativně lze vypsat znovu příkazem.
```bash
#Vytvoření API s názvem LocalHelloAPI, vrátí API ID
aws apigateway create-rest-api \
  --name "LocalHelloAPI" \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  --query 'id' --output text
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
- Vrátí root ID
```bash
aws apigateway get-resources \
--rest-api-id <API_ID> \
--region "eu-central-1" \
--endpoint-url "http://localhost:4566" \
--query 'items[0].id' --output text
```

##### Krok 3 Vytvoření nového resource
Vytvoříme si resource /hello. Během vytváření specifikujeme parent_id jako root resource ID a api ID, aby bylo jasné, ve které API se to má vytvořit.
Získáme ID resource, které je důležité pro další kroky.
Vrátí ID resource (HELLO_ID).
```bash
aws apigateway create-resource \
  --rest-api-id <API_ID> \
  --parent-id <ROOT_ID> \
  --path-part hello \
  --region "eu-central-1" \
  --endpoint-url "http://localhost:4566" \
  --query 'id' --output text
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
  # Specifikace co má přijímat Lambda funkce
  --request-templates '{"application/json":"$input.body"}' \ 
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

### Bonusový úkol, práce s DynamoDB (volitelně)
#### Vytvoření tabulky
```bash
aws dynamodb create-table \
  --table-name names \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1 \
  --endpoint-url http://localhost:4566
```

#### Ověření existence tabulky
```bash
aws dynamodb list-tables \
  --endpoint-url http://localhost:4566 \
  --region eu-central-1

```

#### Vložení dat do tabulky ručně
```bash
aws dynamodb put-item \
  --table-name names \
  --item '{
        "id": {"S": "1"},
        "name": {"S": "Pavel"}
    }' \
  --region eu-central-1 \
  --endpoint-url http://localhost:4566
```

#### Získání jednoho záznamu
```bash
aws dynamodb get-item \
--table-name names \
--key '{"id": {"S": "1"}}' \
--region eu-central-1 \
--endpoint-url http://localhost:4566 \
--output json
```

#### Načtení všech záznamů
```bash
aws dynamodb scan \
--table-name names \
--region eu-central-1 \
--endpoint-url http://localhost:4566 \
--output json
```

#### Více informací a propojení s AWS Lambda
https://docs.aws.amazon.com/lambda/latest/dg/welcome.html

## Shrnutí
V tomto workshopu jste si vyzkoušeli:

- psaní Kotlin Lambda funkcí

- kompilaci a balení pomocí Gradlu

- nasazení a testování funkcí přes AWS CLI

- práci s LocalStackem jako plnohodnotným lokálním AWS cloudem

- propojení Lambda → API Gateway

- (volitelně) práci s DynamoDB

Tento základní serverless stack tvoří stavební kámen moderních cloud-native aplikací. Kombinace AWS Lambda a API Gateway vám umožní vytvářet škálovatelné, úsporné a snadno spravovatelné mikroslužby.

## Časté chyby
### Lambda zůstává ve stavu Pending
```bash
docker compose down
rm -rf localstack_data
docker compose up -d
```
### Function already exist
```bash
aws lambda delete-function \
--function-name <FUNCTION_NAME> \
--endpoint-url http://localhost:4566
#znovu vytvořit funkci
```

### Při buildu nevzniká JAR nebo je prázdný

### Nelze spustit připravený script
```bash
chmod +x
```


