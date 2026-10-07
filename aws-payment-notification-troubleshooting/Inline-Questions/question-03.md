## MetaData
Question Type : Single Choice
Marks : 2

## Question
A PAYNOTIFY EC2 instance has an inbound security group rule allowing TCP 443 from the application subnet. The instance can receive the connection, but return traffic is not explicitly allowed in the security group. A network ACL is also associated with the subnet. Which statement correctly explains how these controls evaluate the traffic?

## Options
Option 1 : The security group is stateful, so it automatically permits the response traffic for an allowed connection; the network ACL is stateless, so its rules must allow both inbound and outbound traffic.
Option 2 : Both the security group and the network ACL are stateful, so allowing inbound TCP 443 automatically permits the response traffic in both controls.
Option 3 : The security group is stateless and requires separate inbound and outbound rules, while the network ACL is stateful and automatically permits response traffic.
Option 4 : Security groups apply only to traffic leaving the subnet, while network ACLs apply only to traffic entering the EC2 instance.

## Answers
Option 1

## Correct Answer Feedback
Option 1 is correct answer, security groups are stateful and automatically allow response traffic for an allowed connection, while network ACLs are stateless and require matching rules in both directions.

## Incorrect Answer Feedback
Selected Option is not correct Option 1 is the correct answer. Security groups are stateful; network ACLs are stateless and require both inbound and outbound rules.

## Number of Retries
1
