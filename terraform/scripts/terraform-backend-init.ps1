# Script para inicializar backend S3 do Terraform
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [string]$Region = "us-east-1"
)

Write-Host "Inicializando backend S3 para ambiente: $Environment" -ForegroundColor Green

# Criar bucket S3
try {
    $bucketExists = aws s3api head-bucket --bucket $BucketName --region $Region 2>$null
    if (-not $bucketExists) {
        Write-Host "Criando bucket S3: $BucketName" -ForegroundColor Yellow
        if ($Region -eq "us-east-1") {
            aws s3api create-bucket --bucket $BucketName --region $Region
        } else {
            aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region
        }
    } else {
        Write-Host "Bucket S3 já existe: $BucketName" -ForegroundColor Green
    }
} catch {
    Write-Host "Erro ao criar bucket: $_" -ForegroundColor Red
}

# Habilitar versionamento
Write-Host "Habilitando versionamento no bucket..." -ForegroundColor Yellow
aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled --region $Region

# Criar tabela DynamoDB para locking
$dynamoTable = "terraform-locks-$Environment"
Write-Host "Criando tabela DynamoDB: $dynamoTable" -ForegroundColor Yellow

try {
    aws dynamodb describe-table --table-name $dynamoTable --region $Region 2>$null
    Write-Host "Tabela DynamoDB já existe: $dynamoTable" -ForegroundColor Green
} catch {
    Write-Host "Criando tabela DynamoDB..." -ForegroundColor Yellow
    aws dynamodb create-table `
        --table-name $dynamoTable `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $Region
}

Write-Host "Backend configurado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Bucket S3: $BucketName"
Write-Host "Tabela DynamoDB: $dynamoTable"
Write-Host "Região: $Region"