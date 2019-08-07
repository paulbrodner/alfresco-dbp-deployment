#!/usr/bin/env bash

dir=$(pwd)

usage() {
  echo -e "Create/Delete Route53 entries"  
  echo -e "\nUsage:\n$  $0 <action>\n"    
  echo -e "   where <action> is one of:"
  echo -e "   --create <route_dns_name> <route_ip_addess>"  
  echo -e "\texample:"
  echo -e "\t$ $0 --create mybranch.dev.alfresco.me ac2b313eaef3311e8bf700212692fddb-1613464265.eu-west-1.elb.amazonaws.com\n"
  echo -e "   --delete <route_dns_name> <route_ip_addess>"  
  echo -e "\texample:"
  echo -e "\t$ $0 --delete mybranch.dev.alfresco.me ac2b313eaef3311e8bf700212692fddb-1613464265.eu-west-1.elb.amazonaws.com"    
}

if [ $# -lt 1 ]; then
  usage
  exit 1
else
  while true; do
      case "$1" in
          -h | --help)
              usage
              exit 1
              ;;
          --create)
              CREATE="true";
              shift
              ;;    
          --delete)
              DELETE="true";
              shift
              ;;                   
          *)
              break
              ;;    
        esac
  done
fi  

set -x
# route_template 'CREATE' 'development' 127.0.0.1
route_template() {
  local action=${1:-'CREATE'}
  local route_dns_name=${2:-'development'}
  local route_ip_address=${3:-'not-set'}

  cat <<EOF >> ${dir}/route-53.json
{
  "Comment":"CNAME for my Deployment",
  "Changes":[{
    "Action": "${action}",
    "ResourceRecordSet":{
      "Name": "${route_dns_name}",
      "Type":"CNAME",
      "TTL":30, 
      "ResourceRecords":[{
        "Value": "${route_ip_address}"
      }]
    }
  }]
}
EOF
}


if [ "$CREATE" = "true" ]; then  
  route_template 'CREATE' $@  
fi
if [ "$DELETE" = "true" ]; then
  route_template 'DELETE' $@
fi

aws route53 change-resource-record-sets  --hosted-zone-id Z15IEG419TWNPC --change-batch file://${dir}/route-53.json
rm file://${dir}/route-53.json
sleep 10