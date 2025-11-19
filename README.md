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

## Struktura projektu

```
prpo_serverless/
├── lambda/
│   ├── src/
│   │   ├── main/
│   │   │   └── kotlin/
│   │   │       └── com/
│   │   │           └── example/
│   │   │               └── Handler.kt
│   │   └── test/
│   ├── build/
│   │   └── libs/
│   │       └── lambda.jar 
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

## Krok za krokem

### Úkol 1: Vytvořte a nahrajte funkci
Naprogramujte funkci v jazyku Kotlin, která:

1. přijme JSON objekt { "name": "Alice" }
2. vrátí "Hello, Alice"
3. loguje čas spuštění

Následně vytvořte její build a nahrajte do AWS Lambda.

#### Řešení
```Kotlin
fun handleRequest(input: Map<String, String>): String { // Map přijme JSON objekt typu key: string, value: string
        val name = input["name"] ?: "Unknown"
        return "Hello, $name!"
    }
```

