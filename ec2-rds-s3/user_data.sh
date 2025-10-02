#!/bin/bash
# EC2 User Data Script for Image Gallery Web Application

# Update system
yum update -y

# Install required packages
yum install -y python3 python3-pip postgresql15 nginx

# Install Python packages
pip3 install flask boto3 psycopg2-binary pillow

# Create application directory
mkdir -p /opt/image-gallery
cd /opt/image-gallery

# Create Flask application
cat > /opt/image-gallery/app.py << 'PYEOF'
from flask import Flask, request, render_template_string, jsonify
import boto3
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

# Database configuration from environment variables
DB_HOST = os.environ.get('DB_HOST')
DB_PORT = os.environ.get('DB_PORT')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USERNAME')
DB_PASS = os.environ.get('DB_PASSWORD')
S3_BUCKET = os.environ.get('S3_BUCKET')
AWS_REGION = os.environ.get('AWS_REGION')

s3_client = boto3.client('s3', region_name=AWS_REGION)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

@app.route('/')
def index():
    return render_template_string('''
        <h1>Image Gallery</h1>
        <h2>Upload Image</h2>
        <form action="/upload" method="post" enctype="multipart/form-data">
            <input type="file" name="file" accept="image/*" required>
            <input type="submit" value="Upload">
        </form>
        <h2>Images</h2>
        <div id="images"></div>
        <script>
            fetch('/api/images')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('images').innerHTML = 
                        data.images.map(img => 
                            `<div><img src="${img.url}" width="200"><p>${img.filename}</p></div>`
                        ).join('');
                });
        </script>
    ''')

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files['file']
    if file:
        filename = f"uploads/{datetime.now().strftime('%Y%m%d_%H%M%S')}_{file.filename}"
        s3_client.upload_fileobj(file, S3_BUCKET, filename)
        return jsonify({'success': True, 'filename': filename})
    return jsonify({'success': False}), 400

@app.route('/api/images')
def list_images():
    # List images from S3
    response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix='uploads/')
    images = []
    if 'Contents' in response:
        for obj in response['Contents']:
            url = s3_client.generate_presigned_url('get_object',
                Params={'Bucket': S3_BUCKET, 'Key': obj['Key']},
                ExpiresIn=3600)
            images.append({'filename': obj['Key'], 'url': url})
    return jsonify({'images': images})

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

# Set environment variables
cat > /opt/image-gallery/.env << EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USERNAME=${db_username}
DB_PASSWORD=${db_password}
S3_BUCKET=${s3_bucket}
AWS_REGION=${region}
EOF

# Create systemd service
cat > /etc/systemd/system/image-gallery.service << EOF
[Unit]
Description=Image Gallery Flask Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/image-gallery
EnvironmentFile=/opt/image-gallery/.env
ExecStart=/usr/bin/python3 /opt/image-gallery/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
cat > /etc/nginx/conf.d/image-gallery.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /health {
        proxy_pass http://127.0.0.1:5000/health;
    }
}
EOF

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf

# Start services
systemctl daemon-reload
systemctl enable image-gallery
systemctl start image-gallery
systemctl enable nginx
systemctl start nginx

# Log completion
echo "User data script completed at $(date)" > /var/log/user-data-complete.log
