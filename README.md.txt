README


Terraform setup:

How to run



Packers:
	Provisions Unix machine from Europe Region and perform below task on AMI;
	· Install suitable docker version for OS
	· Install Ansible
	· Download SpringBoot artifact
	· Build docker image and tag as springboot/app:latest
	· Run latest springboot/app latest image on machine
	· Run ansible-playbook (install git, nginx) Test Docker image is running
	· Save AMI in AWS as name like prod-image*
		


