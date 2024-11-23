# Create a DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.name}-rdsubnetgroup"
  description = "Subnet group for RDS instance across multiple AZs"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.name}-rdsubnetgroup"
  }
}

# Create a Security Group to Control Access
resource "aws_security_group" "rds_security_group" {
  name        = "${var.name}-rdssecuritygroup"
  description = "Allow access to the RDS instance"
  vpc_id      = var.vpc_id  

  # Ingress rule to allow access to the database
  ingress {
    description = "mysqlport"
    from_port   = 3306                  
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [var.bastion-sg]     
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rdssecuritygroup"
  }
}

# Create the RDS Instance
resource "aws_db_instance" "rds_instance" {
  identifier             = "petclinic"
  instance_class         = "db.t3.micro"          
  engine                 = "mysql"                 # Specify database engine (e.g., mysql, postgres)
  engine_version         = "8.0"
  parameter_group_name   = "default.mysql8.0"                
  allocated_storage      = 20                      # Storage in GB
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  multi_az               = false                    # Enables Multi-AZ deployment
  publicly_accessible    = false                   # Ensures instance is not publicly accessible
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  skip_final_snapshot    = true                    # Set to false in production to retain snapshots
  tags = {
    Name        = "${var.name}-rdsinstance"
  }
}