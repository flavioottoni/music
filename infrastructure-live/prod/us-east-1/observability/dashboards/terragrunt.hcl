resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "SoundWave-Overview"

  dashboard_body = jsonencode({
    widgets =,
           
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS Cluster Utilization"
        }
      }
    ]
  })
}