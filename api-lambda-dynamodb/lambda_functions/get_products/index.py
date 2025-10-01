import json
import boto3
import os
from decimal import Decimal
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    Lambda function to get all products from DynamoDB
    
    API Gateway Event structure:
    - event['httpMethod']: GET
    - event['queryStringParameters']: Optional query params (limit, category, etc.)
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Get query parameters (optional)
        query_params = event.get('queryStringParameters', {}) or {}
        
        # Scan the table (get all items)
        # Note: For production, consider using Query with pagination for better performance
        response = table.scan()
        
        products = response.get('Items', [])
        
        # Optional: Filter by category if provided
        category = query_params.get('category')
        if category:
            products = [p for p in products if p.get('category') == category]
        
        # Optional: Limit results
        limit = query_params.get('limit')
        if limit:
            try:
                limit = int(limit)
                products = products[:limit]
            except ValueError:
                pass
        
        # Sort by createdAt (newest first)
        products.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
        
        print(f"Retrieved {len(products)} products")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Enable CORS
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps({
                'success': True,
                'count': len(products),
                'products': products
            }, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error',
                'message': str(e)
            })
        }
