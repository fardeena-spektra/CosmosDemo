# Exercise 3: Review the PAYNOTIFY Network Basics

## Overview

A reliable payment-notification service depends on more than application configuration. Network boundaries, subnet routing, traffic filters, gateways, and DNS settings determine whether workloads can communicate and reach the services they need.

In this review activity, you will inspect the PAYNOTIFY network in the AWS Management Console and answer six short troubleshooting questions. The questions are independent of the S3 and Lambda repairs and use general AWS networking concepts.

**Objective:** demonstrate your understanding of VPCs and subnets, security groups and network ACLs, internet and NAT gateways, DNS, and route tables.

## Sign in to the AWS console

1. From the CloudLabs Environment tab, open the AWS console using the provided credentials. If you are working from the lab VM, open the AWS console shortcut in Microsoft Edge.
2. Use the AWS console URL <inject key="AwsConsoleUrl"></inject>, user name <inject key="IamUserName"></inject>, and password <inject key="IamUserPassword"></inject>.
3. Confirm that the Region selector is set to **US East (N. Virginia)** (`us-east-1`).

## Review the deployed network

Use the console to review the resources before answering the questions. Do not modify the network.

1. In the AWS console search bar, search for **VPC**, then choose **VPC**.
2. In the left navigation pane, choose **Your VPCs**. Locate the PAYNOTIFY VPC and note that its IPv4 CIDR is `10.10.0.0/16`.
3. Choose **Subnets** and locate the subnet with IPv4 CIDR `10.10.1.0/24`. Review its Availability Zone and VPC association.
4. Choose **Route tables**. Review the route table associated with the PAYNOTIFY subnet and identify the default route to the internet gateway.
5. Choose **Internet gateways** and review the gateway attached to the PAYNOTIFY VPC. An internet gateway must be attached to a VPC and referenced by the subnet's route table for direct internet routing.
6. Choose **Security groups** and review the security group associated with the lab VM. Then choose **Network ACLs** and compare the subnet-level network ACL rules with the instance-level security-group rules.
7. In the left navigation pane, choose **Your VPCs**, select the PAYNOTIFY VPC, and review the **Details** area for the DNS support and DNS hostnames settings. These settings affect VPC DNS behavior; they do not replace route-table entries.

![Image placeholder: VPC console showing the PAYNOTIFY VPC, subnet, and network resources](images/exercise-03-01.png)

## Answer the networking questions

Answer the six single-choice questions below. Each question is worth **2 marks**, for **12 marks total**. You have **one retry per question**. Select one option for each question; if your first selection is incorrect, use the retry to reconsider the scenario and choose again.

The questions cover the following areas:

- VPC CIDR ranges, VPC boundaries, and subnet scope.
- Public and private subnet behavior.
- Stateful security groups and stateless network ACLs.
- Internet gateway attachment and public routing.
- NAT gateway purpose and private-subnet egress.
- VPC DNS settings, route-table association, and routing troubleshooting.

### Question 1 — VPCs and subnets

<question file="../../Inline-Questions/question-01.md" />

### Question 2 — Public and private subnets

<question file="../../Inline-Questions/question-02.md" />

### Question 3 — Security groups and network ACLs

<question file="../../Inline-Questions/question-03.md" />

### Question 4 — Internet gateways and public routing

<question file="../../Inline-Questions/question-04.md" />

### Question 5 — NAT gateways and private-subnet egress

<question file="../../Inline-Questions/question-05.md" />

### Question 6 — DNS and route troubleshooting

<question file="../../Inline-Questions/question-06.md" />

## Completion summary

You completed a six-question networking review covering the core path from a VPC and subnet to filtered traffic, gateway routing, and DNS resolution.

- **Questions:** 6 single-choice questions.
- **Marks:** 2 marks per question, 12 marks total.
- **Retry policy:** one retry per question.

A subnet is a range of IP addresses inside a VPC and is associated with one Availability Zone. Security groups filter traffic at the resource network-interface level and are stateful, while network ACLs filter traffic at the subnet boundary and are stateless. An internet gateway supports direct internet routing when attached to the VPC and selected by the effective subnet route table; a NAT gateway provides outbound access for private-subnet resources without accepting unsolicited inbound connections. VPC DNS settings and route-table associations address different parts of name resolution and packet forwarding.
