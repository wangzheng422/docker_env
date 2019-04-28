# 1. Solar Village
Solar Village home work assignment for advanced process development with nodejs restapi.

# 2. Instructions

to setup nodejs env, copy server.js and data.json to somewhere in you server folder. then

```bash
node server.js
```

the server will lisent to port 5000.

to setup this pam project, setup a git repository with the zip file, and import the project into process automation system, build and deploy.

# test steps

1. find out containers

```bash
curl -u "pamAdmin:redhatpam1\!" -X GET "http://v2.wandering.wang:8080/kie-server/services/rest/server/containers" -H "accept: application/json"

curl -u "pamAdmin:redhatpam1\!" -X GET "http://v2.wandering.wang:8080/kie-server/services/rest/server/queries/containers/pam_1.0.0-SNAPSHOT/processes/definitions?page=0&pageSize=10&sortOrder=true" -H "accept: application/json"

```

2. create a new case

```bash
curl -u "pamAdmin:redhatpam1\!"  -X POST "http://v2.wandering.wang:8080/kie-server/services/rest/server/containers/pam_1.0.0-SNAPSHOT/processes/pam.OrderPermit/instances" -H "accept: application/json" -H "content-type: application/json" -d "{}"

```

3. list tasks

```bash
curl -u "pamAdmin:redhatpam1\!"  -X GET "http://v2.wandering.wang:8080/kie-server/services/rest/server/queries/tasks/instances/pot-owners?page=0&pageSize=10&sortOrder=true" -H "accept: application/json"
```

4. claim and complete tasks

```bash
curl -u "pamAdmin:redhatpam1\!" -X PUT "http://v2.wandering.wang:8080/kie-server/services/rest/server/containers/pam_1.0.0-SNAPSHOT/tasks/9/states/claimed" -H "accept: application/json"

curl -u "pamAdmin:redhatpam1\!" -X PUT "http://v2.wandering.wang:8080/kie-server/services/rest/server/containers/pam_1.0.0-SNAPSHOT/tasks/9/states/started" -H "accept: application/json"

curl -u "pamAdmin:redhatpam1\!" -X PUT "http://v2.wandering.wang:8080/kie-server/services/rest/server/containers/pam_1.0.0-SNAPSHOT/tasks/9/states/completed" -H "accept: application/json" -H "content-type: application/json" -d "{}"

```