# about
> Cluster related scripts. On this cluster you will deploy the DBP

# prerequisites
- [x] [aws-cli](https://aws.amazon.com/cli/) installed & configured
- [x] [eksctl](https://github.com/weaveworks/eksctl) installed
- [x] [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed
- [x] [helm](https://helm.sh/docs/using_helm/) installed

# usage
- create once the AWS cluster using [./create-cluster.sh](./create-cluster.sh) script
   * check the [eksctl.yml](./eksctl.yaml) for details
- delete the cluster with [./delete-cluster.sh](./delete-cluster.sh) script
