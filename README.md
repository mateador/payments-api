
## Payments-API
Payments-API to practice the a Java application with API, connecting to a local machine with Oracle - using stored procedures
There will be an API and a connection to a Oracle database.

### How to run the project
- Exec the oracle machine 
- 

### How to update the project on GitHub
- Push the changes to the GitHub repository

### Installing Oracle locally on Linux
The easiest path by far is Docker, using Oracle Database Free (the free tier Oracle officially publishes):

#### 1. Pull the official Oracle Free image
```
docker pull container-registry.oracle.com/database/free:latest
```
#### 2. Run it (first run takes 3–5 minutes to initialise)
```
docker run -d \
--name oracle-local \
-p 1521:1521 \
-e ORACLE_PWD=YourPassword123 \
container-registry.oracle.com/database/free:latest
```
#### 3. Check it's ready (look for "DATABASE IS READY TO USE!")
```
docker logs -f oracle-local
```
#### 4. Connect with SQL*Plus inside the container
```
docker exec -it oracle-local sqlplus system/YourPassword123@//localhost:1521/FREE
```
#### 5. Just to check if it's working
```
SELECT CURRENT_TIMESTAMP FROM dual; 
```
