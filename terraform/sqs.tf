# SQS Queue
resource "aws_sqs_queue" "iot_event_queue" {
  name                        = "${var.acc}-iot-event-queue.fifo"
  content_based_deduplication = true
  fifo_queue                  = true
  tags = {
    Name = "${var.acc}-iot-queue"
  }
}

resource "aws_lambda_event_source_mapping" "lambda_sqs_trigger" {
  event_source_arn = aws_sqs_queue.iot_event_queue.arn
  function_name    = aws_lambda_function.eh_lambda.arn
  batch_size       = 5
  enabled          = true
}