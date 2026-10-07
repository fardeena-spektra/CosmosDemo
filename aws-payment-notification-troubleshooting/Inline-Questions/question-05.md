## MetaData
Question Type : Single Choice
Marks : 2

## Question
A workload in a private subnet must initiate outbound HTTPS connections to public AWS services, but it must not accept unsolicited inbound connections from the internet. Which design provides this private-subnet egress?

## Options
Option 1 : Attach an internet gateway directly to the private subnet and add a default route to it.
Option 2 : Place a NAT gateway in a public subnet with a route to the internet gateway, then route the private subnet's `0.0.0.0/0` traffic to the NAT gateway.
Option 3 : Add an internet gateway route to the private subnet and rely on the security group to prevent all inbound connections.
Option 4 : Place a NAT gateway in the private subnet and route its traffic directly to the public internet without an internet gateway.

## Answers
Option 2

## Correct Answer Feedback
Option 2 is correct answer, a NAT gateway in a public subnet uses an internet gateway for outbound connectivity, while the private subnet routes internet-bound traffic to the NAT gateway and does not need a direct route to the internet gateway.

## Incorrect Answer Feedback
Selected Option is not correct Option 2 is the correct answer. A private subnet uses a route to a NAT gateway for outbound internet access; the NAT gateway must be in a public subnet with a route to an internet gateway.

## Number of Retries
1
