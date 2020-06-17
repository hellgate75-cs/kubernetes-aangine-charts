<p align="center">
<img width="250" height="230" src="images/helm-logo.png"></img>
</p><br/>

# Kubernetes Aangine Charts

Aangine Kubernetes Clusters Chart Repository

## Helm Repo Content

This is a Helm Repository containing 2 charts in release:

* [aangine-backend](/aangine-backend-charts) - Aangine Backend Service Layer Charts

* [aangine-database](/aangine-database-charts) - Aangine MongoDb NoSql Database Layer Chart

* [aangine-frontend](/aangine-frontend-charts) - Aangine Backend Apps Layer Chart

* [aangine-platform](/aangine-platform-charts) - Aangine Platform Service Layer Chart

* [aangine-system](/aangine-system-charts) - Aangine System Service Layer Chart

## How to use it

Run command to add the repository

```
> helm repo add aangine-release git@gitlab.com:aangine/kubernetes/kubernetes-aangine-charts.git

> helm repo update
```

Now your repo has been installed!!

## How to claim for a Chart in a K8s Cluster Namespace

Please refer to Jenkins Jobs procedures in repository:

* [Kubernetes Jenkins DevOps](https://gitlab.com/aangine/kubernetes/kubernetes-jenkins-procedures)

Please refer to deploy procedure written in repository: 

* [Kubernetes Docker Machine](https://gitlab.com/aangine/kubernetes/kubernetes-docker-machine)

Enjoy your experience

## License

Express All rights reserved by Continuous Software Ltd, author: [Fabrizio Torelli](mailto:fabrizio.torelli@optiim.com)