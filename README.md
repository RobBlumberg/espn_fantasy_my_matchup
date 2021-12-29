# ESPN Fantasy Basketball - My Matchup Helper

This repo contains code to analyze weekly fantasy basketball matchups between my team and my opponent's team. To accomplish this, I am making use of a python package I created, called [espn_fantasy_matchup_stats](https://github.com/RobBlumberg/espn_fantasy_matchup_stats), which predicts the outcome of a weekly fantasy matchup (see link to github repo for details).

The primary purpose of this project is to deploy a trivial model using AWS lambda. This project thus serves as a learning exercise, focusing on the requirements for deployment. As such, these requirement will be documented throughout this repo, in particular in this README, where the role of each component of the code will be explained.

## Deployment

- Build docker image and push to ECR 
```
make build
make push
```

- Provision infrastructure
```
terraform plan
terraform apply
```