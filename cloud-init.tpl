#cloud-config
repo_update: true
repo_upgrade: all

packages:
 - awslogs

runcmd:
 - [ sh, -c, 'sudo touch /var/log/${log_name}' ]
 - [ sh, -c, 'echo "" | sudo tee -a /etc/awslogs/awslogs.conf'] 
 - [ sh, -c, 'echo [/var/log/${log_name}] | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "file = /var/log/${log_name}" | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "log_stream_name = {instance_id}" | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "log_group_name  = /var/log/${log_name}" | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "inital_position  = start_of_file" | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "buffer_duration  = 5000" | sudo tee -a /etc/awslogs/awslogs.conf' ]
 - [ sh, -c, 'echo "datetime_format = %b %d %H:%M:%S"| sudo tee -a /etc/awslogs/awslogs.conf' ]
 - sudo systemctl start awslogsd
 - sudo systemctl enable awslogsd.service


