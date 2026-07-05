
## Payments-API
Payments-API to practice the a Java application with API, connecting to a local machine with Oracle - using stored procedures
There will be an API and a connection to a Oracle database.

### First version
1. Build an application to request the current time from an Oracle database.
2. Adding test classes to test the application, with TestNG.


### How to run the project
- Exec the oracle machine 

### Request by curl - valid request
```
curl -X POST http://localhost:8080/api/payment/get-date \
-H "Content-Type: application/json" \
-d '{
    "accountId": "ACC-001",
    "amount": 150.00,
    "currency": "GBP",
    "merchantId": "MERCH-42",
    "idempotencyKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}'
```
#### Invalid request
```
curl -X POST http://localhost:8080/api/payment/get-date \
-H "Content-Type: application/json" \
-d '{
    "accountId": "ACC-001",
    "amount": 150.00,
    "currency": "GBP",
    "merchantId": "MERCH-999",
    "idempotencyKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}'
```

#### Invalid request
```
curl -X POST http://localhost:8080/api/payment/get-date \
-H "Content-Type: application/json" \
-d ''
```

### Example of a valid request
```
{
    "accountId": "ACC-001",
    "amount": 150.00,
    "currency": "GBP",
    "merchantId": "MERCH-42",
    "idempotencyKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

### Example of a valid response
```
{
  "transactionId": "TXN-20240621-001",
  "status": "APPROVED",
  "accountId": "ACC-001",
  "amount": 150.00,
  "currency": "GBP",
  "merchantId": "MERCH-42",
  "message": "Payment processed successfully",
  "processedAt": "2024-06-21T14:32:00"
}
```

### How to update the project on GitHub
- Push the changes to the GitHub repository

### Requirements for testsing
- Selenium WebDriver - Maven Repository: org.seleniumhq.selenium » selenium-java (mvnrepository.com)
- TestNG - Maven Repository: org.testng » testng (mvnrepository.com)

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
docker start oracle-local
docker exec -it oracle-local sqlplus system/YourPassword123@//localhost:1521/FREE
```
#### 5. Just to check if it's working
```
SELECT CURRENT_TIMESTAMP FROM dual; 
```

### How to commit the changes
- git status (in the correct directory)
- Adding new files to the stage: commit add <file>
- Adding all deleted and modified files to stage: commit add -u
- Committing the changes: commit -m "<message>"
- Pushing the changes to the remote repository: push origin 

### How to execute the SQL script from the docker container
- Considering the file:
  - src/main/java/com/example/paymentsapi/model/payment_api_database.sql
- Copy the file to the docker container 'oracle-local:
```
docker cp /src/main/java/com/example/paymentsapi/model/payment_api_database.sql oracle-local:/tmp/payment_api_database.sql
```
- Run the file from the command SQL:
```
@/path/to/payment_api_database.sql
```