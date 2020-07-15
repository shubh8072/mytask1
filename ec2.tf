provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIA2YIADDJH7JJZFIEA"
  secret_key = "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"
}
resource "aws_instance" "os3" {
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
key_name = "shubham0"
security_groups=["serviceSG"]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Shailendra Gupta/Downloads/shubham0.pem")
    host     = aws_instance.os3.public_ip
  } 
provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      "sudo git clone https://github.com/shubh8072/shubham123.git /var/www/html"    
]
  }

  tags = {
    Name = "HelloWorld3"
  }
}
output "op3"{
value=aws_instance.os3.public_ip
}



resource "aws_ebs_volume" "EBS1" {
  availability_zone = aws_instance.os3.availability_zone
  size              = 1

  tags = {
    Name = "myhd4"  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.EBS1.id}"
  instance_id = "${aws_instance.os3.id}"
}



resource "null_resource" "null1" {

	depends_on = [
		aws_volume_attachment.ebs_att
	]
	connection {
                type = "ssh"
                user = "ec2-user"
                private_key = file("C:/Users/Shailendra Gupta/Downloads/shubham0.pem")
                host = aws_instance.os3.public_ip
        }


        provisioner "remote-exec" {
                inline = [
                        "sudo mkfs.ext4 /dev/sdh",
                        "sudo mount /dev/sdh /var/www/html",
			            "sudo rm -rf /var/www/html/*"
                ]
        }
}
 resource "aws_s3_bucket" "mybucket904" {
      bucket = "mybucket904"
      acl = "private"
      force_destroy = true
      tags = {
          Name = "mybucket904"
    }
  }
 resource "aws_s3_bucket_object" "image-pull"{
      depends_on = ["aws_s3_bucket.mybucket904",]      
      bucket  = "aws_s3_bucket.mybucket904.bucket"
      key     = "IMG_20190419_123003.jpg"
      source  = "D:/my mobile data/camera/IMG_20190419_123003.jpg"
      acl     = "public-read"
}
 resource "aws_cloudfront_origin_access_identity" "originAccessIdentity" {
      comment = "access-identity-mybucket904"
  }
 resource "aws_cloudfront_distribution" "s3Distribution" {
      depends_on = [
          aws_s3_bucket.mybucket904,
          aws_cloudfront_origin_access_identity.originAccessIdentity
      ]
      origin {
          domain_name = aws_s3_bucket.mybucket904.bucket_regional_domain_name
          origin_id   = local.s3_origin_id

          s3_origin_config {
              origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.originAccessIdentity.id}"
          }
      }

      enabled             = true
      is_ipv6_enabled     = true

      default_cache_behavior {
          allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
          cached_methods   = ["GET", "HEAD"]
          target_origin_id = local.s3_origin_id

          forwarded_values {
              query_string = false

              cookies {
                  forward = "none"
              }
          }

          viewer_protocol_policy = "allow-all"
          min_ttl                = 0
          default_ttl            = 3600
          max_ttl                = 86400
      }

      wait_for_deployment = false
      restrictions {
          geo_restriction {
              restriction_type = "whitelist"
              locations        = ["US", "CA", "IN"]
          }
      }

      tags = {
          Environment = "Production"
      }

      viewer_certificate {
          cloudfront_default_certificate = true
      }
  }
 data "aws_iam_policy_document" "s3Policy" {
      statement {
          actions   = ["s3:GetObject"]
          resources = ["${aws_s3_bucket.mybucket904.arn}/*"]

          principals {
              type        = "AWS"
              identifiers = ["${aws_cloudfront_origin_access_identity.originAccessIdentity.iam_arn}"]
          }
      }

      statement {
          actions   = ["s3:ListBucket"]
          resources = ["${aws_s3_bucket.mybucket904.arn}"]

          principals {
              type        = "AWS"
              identifiers = ["${aws_cloudfront_origin_access_identity.originAccessIdentity.iam_arn}"]
          }
      }
  }
 resource "aws_s3_bucket_policy" "bucketReadPolicy" {
      depends_on = [
          aws_s3_bucket.mybucket904
      ]
      bucket = aws_s3_bucket.mybucket904.id
      policy = data.aws_iam_policy_document.s3Policy.json
  }
 resource "null_resource" "updateURL" {
      depends_on = [
          aws_cloudfront_distribution.s3Distribution,
          aws_instance.os1,
          null_resource.EBS1
      ]

      connection {
          type     = "ssh"
          user     = "ec2-user"
          private_key = tls_private_key.keyGenerate.private_key_pem
          host     = aws_instance.web.public_ip
      }

      provisioner "remote-exec" {
          inline = [
              "sudo sed -i 's|url|https://${aws_cloudfront_distribution.s3Distribution.domain_name}|g' /var/www/html/first.html"
          ]
      }
  }
  
  output "os1ip" {
      value = aws_instance.os1.public_ip
  }
resource "null_resource" "localnull222"  {

depends_on = [
    
aws_cloudfront_distribution.s3_distribution,
 ]

	
provisioner "local-exec" {
	    
command = "start chrome  ${aws_instance.os1.public_ip}"
  	
}

}
 resource "null_resource" "showSite" {
      depends_on = [
          aws_cloudfront_distribution.s3Distribution,
          null_resource.updateURL
      ]

      provisioner "local-exec" {
          command = "firefox http://${aws_instance.os1.public_ip}/index.html &"
      }

  }