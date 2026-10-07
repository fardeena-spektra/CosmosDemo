## MetaData
Question Type : Single Choice
Marks : 2

## Question
A troubleshooting engineer launches an EC2 instance in a subnet intended to be public. The instance has a public IPv4 address, but it cannot reach the internet. Which configuration is required for the subnet to provide internet connectivity through an internet gateway?

## Options
Option 1 : The VPC must have an internet gateway attached, and the subnet's route table must include a `0.0.0.0/0` route whose target is that internet gateway.
Option 2 : The subnet must have a route to a NAT gateway, and the NAT gateway must be attached directly to the VPC's internet gateway.
Option 3 : The instance's security group must include an inbound rule allowing `0.0.0.0/0`; route-table and internet-gateway configuration is optional.
Option 4 : The subnet must be associated with the VPC's default route table; custom route tables cannot route traffic through an internet gateway.

## Answers
Option 1

## Correct Answer Feedback
Option 1 is correct answer, a public subnet requires a route to an internet gateway in its associated route table, and the internet gateway must be attached to the VPC. The instance also needs a public IPv4 address and suitable security-group and network-ACL rules.

## Incorrect Answer Feedback
Selected Option is not correct Option 1 is the correct answer. An internet gateway must be attached to the VPC and the subnet's associated route table must send internet-bound traffic, such as `0.0.0.0/0`, to that gateway.

## Number of Retries
1