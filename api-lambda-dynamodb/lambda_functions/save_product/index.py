import json
import boto3
import os
import uuid
from decimal import Decimal
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Lambda function to save a new product to DynamoDB
    
    API Gateway Event structure:
    - event['httpMethod']: POST
    - event['body']: JSON string with product data
    
    Expected body format:
    {
        "name": "Product Name",
        "description": "Product description",
        "price": 99.99,
        "category": "Electronics"
    }
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse request body
        if not event.get('body'):
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing request body'
                })
            }
        
        body = json.loads(event['body'])
        
        # Validate required fields
        if 'name' not in body:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing required field: name'
                })
            }
        
        if 'price' not in body:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing required field: price'
                })
            }
        
        # Validate price is a number
        try:
            price = Decimal(str(body['price']))
            if price < 0:
                raise ValueError("Price cannot be negative")
        except (ValueError, TypeError) as e:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': f'Invalid price: {str(e)}'
                })
            }
        
        # Generate unique product ID
        product_id = str(uuid.uuid4())
        
        # Get current timestamp
        timestamp = datetime.utcnow().isoformat()
        
        # Create product item
        product = {
            'productId': product_id,
            'name': body['name'],
            'description': body.get('description', ''),
            'price': price,
            'category': body.get('category', 'Uncategorized'),
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Save to DynamoDB
        table.put_item(Item=product)
        
        print(f"Product created: {product_id}")
        
        # Return success response
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'success': True,
                'message': 'Product created successfully',
                'product': {
                    'productId': product_id,
                    'name': product['name'],
                    'description': product['description'],
                    'price': float(price),
                    'category': product['category'],
                    'createdAt': product['createdAt'],
                    'updatedAt': product['updatedAt']
                }
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Invalid JSON in request body'
            })
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
