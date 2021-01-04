# PaaS / Serverless Terraform example

Advanced example of using Terraform and Azure for a severless API solution.

Due to default host keys not being generated for Azure functions until after a code deployment, this terraform deployment happens in x2 steps. I don't really like the local-exec provionser approach, which I could use to keep this as 1 deployment.
