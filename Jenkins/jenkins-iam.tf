# Create IAM instance profile for jenkins server
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role-trial"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "jenkins_role_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Attach the IAM role to an IAM instance profile
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins_instance_profile2"
  role = aws_iam_role.jenkins_role.name
}