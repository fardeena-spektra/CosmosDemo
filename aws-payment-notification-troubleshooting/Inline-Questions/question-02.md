## MetaData
Question Type : Single Choice
Marks : 2

## Question
A troubleshooting engineer launches an EC2 instance in a subnet whose route table contains `0.0.0.0/0` pointing to an internet gateway. Which statement correctly describes the subnet and the instance's internet connectivity?

## Options
Option 1 : The subnet is public; the instance can use the internet gateway for internet traffic when it has a public IPv4 address or Elastic IP address.
Option 2 : The subnet is private; an internet gateway automatically provides internet access to every instance without a public IP address.
Option 3 : The subnet is public; every instance automatically receives a public IPv4 address even when auto-assign public IPv4 is disabled.
Option 4 : The subnet is private; outbound internet access is available only after attaching a NAT gateway directly to the instance's network interface.

## Answers
Option 1

## Correct Answer Feedback
Option 1 is correct answer, a subnet is considered public when its route table has a route to an internet gateway. An instance also needs a public IPv4 address or Elastic IP address, and its security controls must allow the traffic, to communicate directly with the internet.

## Incorrect Answer Feedback
Selected Option is not correct Option 1 is the correct answer. A route to an internet gateway makes the subnet public, but an instance needs a public IP address for direct internet communication; private-subnet egress commonly uses a NAT gateway.

## Number of Retries
1
