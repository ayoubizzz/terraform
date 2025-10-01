# Products API Terraform Configuration

This directory contains Terraform configuration for a serverless REST API that manages products using AWS Lambda, API Gateway, and DynamoDB.

## Architecture

```
API Gateway (REST API)
  ├── GET /products → Lambda (GetProducts) → DynamoDB
  └── POST /products → Lambda (SaveProduct) → DynamoDB
```

## Components

- **API Gateway**: REST API with GET and POST endpoints
- **Lambda Functions**:
  - `GetProducts`: Retrieves all products (supports filtering and pagination)
  - `SaveProduct`: Creates new products with validation
- **DynamoDB**: NoSQL database for storing products
- **IAM Roles**: Separate roles for each Lambda (least privilege)
- **CloudWatch Logs**: Logging for API Gateway and Lambda functions

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with credentials
- Python 3.11 (for Lambda functions)

## File Structure

```
ec2-rds-s3/
├── main.tf                    # Terraform and provider configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values (API URL, etc.)
├── dynamodb.tf                # DynamoDB table definition
├── lambda-iam.tf              # IAM roles and policies for Lambda
├── lambda.tf                  # Lambda function definitions
├── api-gateway.tf             # API Gateway configuration
├── lambda_functions/
│   ├── get_products/
│   │   └── index.py          # GetProducts Lambda code
│   └── save_product/
│       └── index.py          # SaveProduct Lambda code
└── README.md                  # This file
```

## Usage

### 1. Initialize Terraform

```bash
cd ec2-rds-s3
terraform init
```

### 2. Review Configuration

Edit `variables.tf` to customize:
- `project_name`: Name prefix for resources (default: "products-api")
- `environment`: Environment name (default: "dev")
- `aws_region`: AWS region (default: "us-east-1")

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

### 5. Get API URL

After deployment, the API URL will be displayed:

```bash
terraform output api_gateway_url
```

Or view all outputs:

```bash
terraform output
```

## Testing the API

### GET /products (List all products)

```bash
# Get all products
curl https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/products

# Filter by category
curl "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/products?category=Electronics"

# Limit results
curl "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/products?limit=10"
```

### POST /products (Create a product)

```bash
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "price": 999.99,
    "category": "Electronics",
    "description": "High-performance laptop"
  }'
```

**Required fields:**
- `name` (string, 1-255 chars)
- `price` (number, >= 0)

**Optional fields:**
- `description` (string, max 1000 chars)
- `category` (string, max 100 chars, default: "Uncategorized")

### Response Format

#### Success (GET)
```json
{
  "success": true,
  "count": 2,
  "products": [
    {
      "productId": "uuid",
      "name": "Laptop",
      "price": 999.99,
      "category": "Electronics",
      "description": "High-performance laptop",
      "createdAt": "2025-10-01T12:00:00.000Z",
      "updatedAt": "2025-10-01T12:00:00.000Z"
    }
  ]
}
```

#### Success (POST)
```json
{
  "success": true,
  "message": "Product created successfully",
  "product": {
    "productId": "uuid",
    "name": "Laptop",
    "price": 999.99,
    "category": "Electronics",
    "description": "High-performance laptop",
    "createdAt": "2025-10-01T12:00:00.000Z",
    "updatedAt": "2025-10-01T12:00:00.000Z"
  }
}
```

#### Error
```json
{
  "success": false,
  "error": "Missing required field: name"
}
```

## DynamoDB Table Schema

**Table Name:** `products-api-products-dev`

**Primary Key:**
- `productId` (String) - UUID generated automatically

**Attributes:**
- `name` (String) - Product name
- `description` (String) - Product description
- `price` (Number) - Product price
- `category` (String) - Product category
- `createdAt` (String) - ISO 8601 timestamp
- `updatedAt` (String) - ISO 8601 timestamp

**Features:**
- Pay-per-request billing (no capacity planning)
- Point-in-time recovery enabled
- Server-side encryption enabled

## IAM Permissions

### GetProducts Lambda Role
- `dynamodb:GetItem` - Get single product
- `dynamodb:Scan` - List all products
- `dynamodb:Query` - Query by index
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` - CloudWatch Logs

### SaveProduct Lambda Role
- `dynamodb:PutItem` - Create product
- `dynamodb:UpdateItem` - Update product
- `dynamodb:GetItem` - Check if product exists
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` - CloudWatch Logs

## Monitoring

### CloudWatch Logs

**API Gateway Logs:**
```bash
aws logs tail /aws/api-gateway/products-api-api-dev --follow
```

**GetProducts Lambda Logs:**
```bash
aws logs tail /aws/lambda/products-api-get-products-dev --follow
```

**SaveProduct Lambda Logs:**
```bash
aws logs tail /aws/lambda/products-api-save-product-dev --follow
```

### CloudWatch Metrics

View metrics in AWS Console:
- API Gateway: Request count, latency, 4XX/5XX errors
- Lambda: Invocations, duration, errors, throttles
- DynamoDB: Read/write capacity, throttled requests

## Cost Estimation

For low traffic (< 1 million requests/month):

- **DynamoDB**: ~$0-5 (free tier: 25GB + 200M requests)
- **Lambda**: ~$0-2 (free tier: 1M requests + 400,000 GB-seconds)
- **API Gateway**: ~$3.50 per million requests
- **CloudWatch Logs**: ~$0.50 per GB ingested

**Total**: ~$0-10/month for development/testing

## Optional Features (Commented Out)

### CORS Configuration
Uncomment the CORS section in `api-gateway.tf` to enable browser access.

### X-Ray Tracing
Set `enable_xray_tracing = true` in `variables.tf` and uncomment X-Ray sections.

### API Key Authentication
Uncomment the Usage Plan and API Key sections in `api-gateway.tf`.

### Global Secondary Index (GSI)
Uncomment the GSI section in `dynamodb.tf` to enable querying by category.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note:** This will delete the DynamoDB table and all data!

## Troubleshooting

### Lambda Permission Errors (500)
- Ensure Lambda permissions are created: `aws_lambda_permission`
- Check CloudWatch logs for detailed errors

### Validation Errors (400)
- Verify request body matches the JSON schema
- Required fields: `name`, `price`

### DynamoDB Errors
- Check IAM policies for Lambda roles
- Verify table name in Lambda environment variables

### API Gateway Not Deploying
- Ensure `depends_on` includes all integrations
- Check `terraform apply` output for errors

## Next Steps

1. **Add Authentication**: Uncomment Cognito or API Key configuration
2. **Enable CORS**: Uncomment CORS section for web frontend
3. **Add More Endpoints**: 
   - `GET /products/{id}` - Get single product
   - `PUT /products/{id}` - Update product
   - `DELETE /products/{id}` - Delete product
4. **Add Pagination**: Implement pagination for large datasets
5. **Add Indexes**: Create GSI for category/price queries
6. **Enable X-Ray**: Uncomment X-Ray tracing for debugging

## Security Best Practices

✅ **Implemented:**
- Separate IAM roles per Lambda (least privilege)
- Request validation before Lambda invocation
- Encrypted DynamoDB table
- CloudWatch logging enabled
- Resource-based Lambda permissions

⚠️ **Consider Adding:**
- API Gateway authentication (Cognito/API Key)
- WAF for DDoS protection
- Private API endpoints (VPC)
- Secrets Manager for sensitive data
- Rate limiting per user/IP

## Support

For issues or questions:
1. Check CloudWatch Logs for errors
2. Review Terraform state: `terraform show`
3. Validate resources in AWS Console
4. Check Lambda function configuration

## License

This configuration is provided as-is for educational purposes.
