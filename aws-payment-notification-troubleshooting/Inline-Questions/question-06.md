## MetaData
Question Type : Single Choice
Marks : 2

## Question
An EC2 instance cannot reach the internet, although its security group allows outbound HTTPS. You find a `0.0.0.0/0` route to an internet gateway in one route table, but the instance is in a subnet that may use another table. What should you check first?

## Options
Option 1 : Confirm which route table is associated with the instance's subnet, then verify that table has the required `0.0.0.0/0` route to the internet gateway
Option 2 : Add an internet gateway route to every route table in every VPC in the AWS account
Option 3 : Replace the subnet's route table with a network ACL that allows outbound HTTPS
Option 4 : Add the instance's private IPv4 address as the destination of the default route

## Answers
Option 1

## Correct Answer Feedback
Option 1 is correct answer, because routes are evaluated from the route table associated with the subnet; the subnet's effective table must contain a default route to an internet gateway for internet-bound traffic.

## Incorrect Answer Feedback
Selected Option is not correct Option 1 is the correct answer. Check the subnet's route-table association and its effective default route before changing security groups or network ACLs.

## Number of Retries
1