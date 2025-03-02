resource "aws_s3_bucket" "website" {
  bucket_prefix = "static-site-"
  force_destroy = true


  tags = {
    Name = "website"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  

}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



# Upload index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "./assets/index.html"
  content_type = "text/html"  # Set MIME type for index.html

  depends_on = [ aws_s3_bucket_public_access_block.website, aws_s3_bucket_policy.website ]  
}

# List of image files to upload
locals {
  images = [
    { key = "images/thai1.jpg", source = "./assets/images/thai1.jpg" },
    { key = "images/thai2.jpg", source = "./assets/images/thai2.jpg" },
    { key = "images/thai3.jpg", source = "./assets/images/thai3.jpg" }
  ]
}

# Upload images dynamically
resource "aws_s3_object" "image" {
  for_each = { for image in local.images : image.key => image }

  bucket       = aws_s3_bucket.website.id
  key          = each.key
  source       = each.value.source
  content_type = "image/jpeg"  # Set MIME type for the images

  depends_on = [ aws_s3_bucket_public_access_block.website, aws_s3_bucket_policy.website ]
}

# Bucket Policy to allow public access to all objects in the bucket
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*" # Allow access to all objects
      }
    ]
  })

  depends_on = [ aws_s3_bucket_public_access_block.website ]
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "bucket_a_index_endpoint" {
  value = "https://${aws_s3_bucket.website.bucket}.s3.us-east-1.amazonaws.com/index.html"
}
