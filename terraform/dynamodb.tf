resource "aws_dynamodb_table" "access_events" {
  name         = "${var.acc}-dynamo-access-events-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "token_id"
  range_key = "timestamp"
  attribute {
    name = "token_id"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = {
    Project = "${var.acc}-access-events-table-db"
  }
}