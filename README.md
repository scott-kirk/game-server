Cost Effective Server Infrastructure
====================================
Motivation
----------
Servers with users in a single timezone often have their activity
localized to just a handful of hours a day. To avoid paying
for the server when no one wants to use it this infrastructure
will handle deploying and cleaning up resources after a certain period
of time.

Implementation
--------------
The project is split into two main components, the Terraform code and
the [Discord](https://discord.com/) chatbot. The Terraform code specifies the [Amazon Web
Services](https://aws.amazon.com/) (AWS) resources required for the game server to function.
Currently it is geared at [MineCraft](https://www.minecraft.net/) servers, however, it can be modified
to support different types of servers as well.

The core resource is an [Auto Scaling group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)
with a preconfigured launch template. The server scaling is accomplished
through scheduled actions on the group, scaling it from 0 to 1 and back.
Manual control is done through lambda functions exposed with public
webhooks, the server can be manually started, stopped, and queried for
its shutdown time.

Cost is nearly entirely from the ec2 while it's running. An Arm-based
t4g.small is sufficient for at least 5 players if the MineCraft chunks
are pre-generated. There is a configurable max cost allowed for the ec2
that defaults to 0.8 cents an hour. Currently a 6Gb EBS volume is used
for data storage.

All required resources for server operation are in the terraform code,
thus a simple `terraform apply` in the terraform directory with the
correct AWS permissions will create a fully usable game server that
can be immediately used. The output of the terraform command will contain
the webhook URLs that can be used for manual server control.

The Discord Bot, based in Rust and the [Serenity library](https://github.com/serenity-rs/serenity),
can be used to serve formatted Prometheus metrics, time until shutdown
and manually control the server lifecycle. This is done through
environment variables which specify the correct Discord channel to serve
status and also the public webhooks that were created as part of the
terraform code. The bot, like all Discord bots, should be running 24/7.
However, it is extremely light on resources and can be easily run
on a Raspberry Pi with no noticeable impact.

To-Do
-----
- [x] Automatic Scheduled Shutdown
- [x] Webhooks for Server Lifecycle
- [x] Chatbot for Server Status
- [x] Chatbot for Server Control
- [x] Metrics Capability
- [x] Configurable Availability Zone
- [ ] Automatic Inactivity Shutdown
- [ ] Configurable Max Price
- [ ] Configurable Instance Type
- [ ] Automatic Backup
