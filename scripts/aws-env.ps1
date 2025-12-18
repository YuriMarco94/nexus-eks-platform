# Ajuste os valores se precisar
$env:AWS_PROFILE="eks-dev"
$env:AWS_REGION="us-east-1"

# Importante no Windows para o SDK ler ~/.aws/config
$env:AWS_SDK_LOAD_CONFIG="1"

# Garante que não está pegando keys antigas por ENV
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

aws sts get-caller-identity
