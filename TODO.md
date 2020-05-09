# CI/Infra TODO

- [ ] What order do scripts need to be run in order to provision correctly (add details to README(s))
- [ ] Can we successfully provision an Elastic Beanstalk stack if the default S3 bucket already exists?
- [ ] Solve issue with CMK policy having principals that are not created until pipeline stack is created
- [ ] Test rolling updates work with zero downtime
- [ ] Only redeploy infra if there are changes
- [ ] Add pre-commit script
- [ ] Add build stage for validating CloudFormation Elastic Beanstalk template before trying to create change set (fail
fast)
- [ ] Abstract commands into functions for Elastic Beanstalk stack-creation script
- [ ] Turn on advanced billing insights for both AWS accounts
- [ ] Script to upload GitHub token to Secrets Manager
- [x] `./go` script to build all infrastructure from scratch (both accounts)
- [ ] Make sure `--profile <profile>` comes in a consistent place after all AWS CLI commands
- [x] `./destroy` script to delete everything in the right order
- [x] Time `destroy`
- [x] Wrap output of terminating env and deleting app in `destroy` so that output is hidden from user
