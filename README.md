
## Nomad for Kraken!!
**[Nomad for Kraken](https://github.com/borei74/kraken.git)**

### Infrastructure Design
Kraken home assignment consisted of nomad single-node deployement, however that approach is not practically usable in almost any environments. I took risk to extend it a bit deploying fully functioning nomad cluster, well with some limitations of cause. So here is infrastructure that was deployed using **Terraform** and **Ansible**. Infra was deployed to AWS cloud:

1. Network Loadbalancers, external and internal.
2. Autoscaling groups - consul servers, nomad servers and nomad clients.
3. Custom built images (without too much customaztion, just to have own images)
4. VPC.
5. Security groups.
6. IAM.
7. Route53 (DNS)

Here VMs running infrastructure:
1. 3 VMs running Nomad servers (cluster management).
2. 4 VMs running Nomad clients (workload).
3. 3 VMs running **[Consul](https://developer.hashicorp.com/consul)**.
4. 1 VM - bootstrap/jumphost

What we are missing here - **[Vault](https://developer.hashicorp.com/vault)** for secrets managenent. For simplicity's sake we are using Consul as for the secrets store, not ideal solution but it works.

Ok, entire infrastructure is on our sholders now, well almost entire - AWS still doing something usefull, and it is doing it really well. But what about **nomad, consul, docker** etc ?  **[Ansible](https://www.ansible.com/)**  was used to deploy hashi stack, docker, and to drop in nomad/consul configuration as well as to load initial policies. There are several simple ansible playbooks and roles that were created to do configuration management:

1. Docker.
2. Consul.
3. Nomad.

All playbooks are not really ready for production, but more or less ok to build PoC sandbox. There tons of things that need to be done:

1. Remove all sensitive information, like tokens, passwords, certificates and load them to proper store (see notice about Vault).
2. Templates need to be improved.
3. Tasks run order need to be changed
4. Etc etc etc.


### Cluster deployment.
At this level cluster deployment is not fully automatated, so some steps need to be done manually. However majority of configuration and orchistration is automated. So, lets pull trigger. All following steps assume that git repo cloned to the local computer with the following software installed:

1. Consul
2. Nomad
3. Terraform
4. Packer
5. Ansible
6. python3-consul - python package to interact with consul from ansible playbooks.

Navigate to the **terraform** directory and simple run:
```
terraform init
terraform apply
```
confirm execution. Please keep in mind that deployment uses custom images. Also variables, defining environment, need to be properly configured.
Once terraform is completed you can move to the next step - ansible.
Navigate to **ansible/playbooks** directory and execute the following:
```
ansible-inventory -i inventories/kraken --graph
@all:
  |--@ungrouped:
  |--@aws_ec2:
  |  |-- TRUNKATED
  |--@consul_clients:
  |  |--172.16.0.10
  |  |--172.16.0.41
  |  |--172.16.0.11
  |  |--172.16.0.55
  |  |--172.16.0.42
  |  |--172.16.0.8
  |  |--172.16.0.24
  |--@nomad_servers:
  |  |--172.16.0.10
  |  |--172.16.0.11
  |  |--172.16.0.42
  |--@consul_servers:
  |  |--172.16.0.39
  |  |--172.16.0.7
  |  |--172.16.0.21
  |--@nomad_clients:
  |  |--172.16.0.41
  |  |--172.16.0.55
  |  |--172.16.0.8
  |  |--172.16.0.24
  |--@nomad_edge:
  |  |--172.16.0.41
  |  |--172.16.0.24
```
Ansible is using AWS dynamic inventory plugin, you don't need to manage Ansible hosts/groups files.

As first step we need to consul servers:
```
ansible-playbook -i inventories/kraken --limit consul_servers consul.yaml
```
Consul ACL bootstraping is not implemented at this moment so you need to do it manually, login to any of the consul servers and run the following:
```
consul acl bootstrap
```
You need to save management token - it's only consul token used in this project. Update **consul_bootstrap_token** ansible variable in **inventories/kraken/group_vars/all** file.
At this moment you should be able to navigate to [Consul](https://consul-kraken.soleks.net:8501/) URL. Connection is not secure, using self-signed cert.
Deploy docker to the nomad client agents:
```
ansible-playbook -i inventories/kraken --limit nomad_clients docker.yaml
``` 
Deploy nomad to the nomad server agents:
```
ansible-playbook -i inventories/kraken --limit nomad_servers nomad.yaml
```
Nomad ACL bootstraping is not implemented at this moment so you need to do it manually, login to any of the nomad servers and run the following:
```
export NOMAD_ADDR=http://172.16.0.10:4646
nomad acl bootstrap
```
You need to save management token - it's only nomad token used in this project. Update **nomad_bootstrap_token** ansible variable in **inventories/kraken/group_vars/all** file
Final step - deploy nomad to the nomad client agents:
```
ansible-playbook -i inventories/kraken --limit nomad_clients nomad.yaml
```
At this moment you should be able to navigate to the [Nomad](http://nomad-kraken.soleks.net:4646/) URL. Connection is not secure, using plain HTTP protocol.

### Workload deployment.

Becaus we are not using any docker repository docker image need to deployed locally on each compute node. For small infrastructure like ours that can be done manually, for bigger ones that approach is not acceptable and we need to look towards complete CI/CD pipeline:

1. Source code
2. Github
3. Jenkinks build
4. Publish to the docker registry - ECR, GCR, on-prem Nexus or Artifactory.
5. Deployment to th cluster.

Copy-over content of **web-service** directory to the compute node. Login to each node and execute the following:
```
docker build -t web-service .
docker tag web-service:latest web-service:v0.1
```
and verify that image is presented:
```
$ docker images
REPOSITORY                    TAG       IMAGE ID       CREATED         SIZE
web-service                   latest    68d70bade08f   5 minutes ago   83.3MB
web-service                   v0.1      68d70bade08f   5 minutes ago   83.3MB
registry.k8s.io/pause-amd64   3.3       0184c1613d92   5 years ago     683kB
```
After that navigate to the local **web-service/nomad** directory and execute:
```
nomad job run web-service.hcl
```
Keep in mind that you need to have the followin env vars:
```
NOMAD_ADDR=http://nomad-kraken.soleks.net:4646
NOMAD_TOKEN=<super_secret_token>
```
and verify that nomad job is up and running:
```
[dan@borei nomad]$ nomad status
ID           Type     Priority  Status   Submit Date
web-service  service  50        running  2025-08-10T21:45:08-07:00

==> View and manage Nomad jobs in the Web UI: http://nomad-kraken.soleks.net:4646/ui/jobs
```
We don't have loadbalancer deployed in our cluster, and because of that it's a bit complecated to verify if our service is actually running, however it can be done and consul will help us with that problem. Go to [Consul](https://consul-kraken.soleks.net:8501/), **Services**. There should be 2 instances of **web-service**. Find the node where it is running from, login to that node and execute:
```
$ curl http://172.16.0.55:27263
{"alloc_id":"0326c43e-0698-5f5e-7b7a-b4a223f73c48","status":"ok"}
```
Our webservice is returning status and nomad allocation id.
Also it can be verified on the service status page of our consul server.

### What is left. Questions section.
**A LOT !!!**
We got infrastructure. We got workload to infrastructure. We got tons of things that need to be completed.

#### SECURITY SECURITY SECURITY.
1. Individual tokens to run job.
2. Nomad workload token to run the job.
3. Segregated nomad workspaces - on per team, on per environment etc.
4. Secrets management using vault with fine-tuned access policies.
5. Access to infrastructure via bastion host.
6. SSH-key based authentication.
7. Revoke permission to run docker previleged containers.

#### Scalability.
Our application can be scaled out based on the number of comming requests - metrics can be collected from envoy proxy via prometheus. Cluster itself can be scaled based on CPU/Mem utilization. 
Nomad autoscaler can do both - application scaling as well as cluster horizontal scaling. In case of sudden traffic surge horizontal cluster scalability doesn't work well - too slow, unless you are keeping preconfigured VMs/hosts in worm standby pool, in such case we are talking about 20-30 seconds to join cluster and pickup load. Ideal situation - cluster has enough capacity to scale application rapidly, only conatianers. In such case we are talking about much shorter enrolment time, however it depends on application type and size of container image, can be 10s of gigs, for example AI/ML workload. Even in such case nodes can be prepopulated with images.


#### Observability.
Pretty standard set of tools:
1. Grafana
2. Prometheus
3. ELK stack
4. Filebeat

All that services can be deployed within the same cluster, confugured to collect logs and metrics.
Key performance metrics for our service are the following:
1. Latenacy.
2. Correctness.
If that 2 metrics within business requirements - we are golden.

#### Troubelshootng.
See all above :-)
Potential issues:
1. Nomad token expired.
2. Consul token expired.
3. SSL cert expired.
4. Docker overlay filesystem is full.
5. OOM killed containers (memory leak or wrong configuration)
From my experience running cluster first 3 issues were affecting entire cluster most significantly. Others - just local problem.
Typically frontend applications are state-less, and they can be run in parallel - so it's not single point of failure. Backend and databases - that is the spot where SPoF issue can popup. 

#### Future improvements.
1. Service Discovery capable loadbalancer. Traffic need to be properly routed to the end points in the nomad cluster. End points are not static, they can migrate from host to host, service ports cab change. Best candidate such purpose is **[Envoy](https://www.envoyproxy.io/)**.
2. Complete monitoring system.
3. CI/CD implementation.
4. Local to the cluster application loadbalancer (envoy or traefik)
5. Application autoscaler.
6. Horizontal Cluster autoscaler.
7. Node classes based on type of workload - for example GPU load, different GPUs etc.
8. Would be super cool to take a look towards network overlays such as Cillium or Callico - is it possible to run in nomad or not, but that is mostly R&D project.
