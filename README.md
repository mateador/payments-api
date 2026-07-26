# Payments API

A Spring Boot REST service that accepts payment authorisation requests, validates them, and
processes them through an Oracle stored procedure.

**Stack:** Java 17 · Spring Boot 3 · Oracle Database Free (Docker) · Maven · TestNG

---

## Why it's built this way

The interesting part of a payments service isn't the happy path — it's the request contract, the
failure modes, and where the transactional logic lives. Three decisions shape this codebase:

**Transaction logic sits in a stored procedure, not in Java.** `process_payment.sql` owns the
authorisation decision. This mirrors how payment processing typically works in an established
enterprise estate, where the database holds decades of accumulated business rules and the service
layer is a controlled entry point to them rather than a replacement for them. It also keeps the
authorisation atomic at the database level.

**Idempotency is part of the request contract, not an afterthought.** Every request carries an
`idempotencyKey`. Payment clients retry — on timeout, on network failure, on user impatience — and a
retry must never produce a second charge. Designing the key into the contract from the first version
is much cheaper than retrofitting it once callers exist.

**Rejections are responses, not exceptions to the caller.** An unknown merchant is a normal business
outcome, not a system fault, and the API distinguishes that from a malformed request. A caller should
be able to tell "your request was wrong", "your request was fine but declined", and "we broke" apart
from each other without parsing a stack trace.

---

## The API

### `POST /api/payments`

**Request**

```json
{
  "accountId": "ACC-001",
  "amount": 150.00,
  "currency": "GBP",
  "merchantId": "MERCH-42",
  "idempotencyKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Response**

```json
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

### Handled cases

| Scenario | Example | Behaviour |
|---|---|---|
| Valid request | `MERCH-42` | Processed through the stored procedure, `APPROVED` returned |
| Unrecognised merchant | `MERCH-999` | Declined with a structured error response |
| Empty or malformed body | `-d ''` | Rejected at validation before reaching the database |

Try them:

```bash
# Valid
curl -X POST http://localhost:8080/api/payments \
  -H "Content-Type: application/json" \
  -d '{"accountId":"ACC-001","amount":150.00,"currency":"GBP","merchantId":"MERCH-42","idempotencyKey":"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}'

# Unrecognised merchant
curl -X POST http://localhost:8080/api/payments \
  -H "Content-Type: application/json" \
  -d '{"accountId":"ACC-001","amount":150.00,"currency":"GBP","merchantId":"MERCH-999","idempotencyKey":"a1b2c3d4-e5f6-7890-abcd-ef1234567890"}'

# Malformed
curl -X POST http://localhost:8080/api/payments \
  -H "Content-Type: application/json" -d ''
```

---

## Running it locally

Everything runs from the repository root, where `pom.xml` lives.

**1. Start Oracle.** The database runs in Docker so the environment is reproducible and disposable —
no local Oracle install, no shared dev database to corrupt.

```bash
docker run -d --name oracle-local -p 1521:1521 \
  -e ORACLE_PWD=YourPassword123 \
  container-registry.oracle.com/database/free:latest
```

First run takes 3–5 minutes to initialise. Watch for `DATABASE IS READY TO USE!`:

```bash
docker logs -f oracle-local
```

On subsequent runs, `docker start oracle-local` is enough.

**2. Load the stored procedure.**

```bash
docker cp src/SQL/process_payment.sql oracle-local:/tmp/process_payment.sql
docker exec -it oracle-local sqlplus system/YourPassword123@//localhost:1521/FREE
```

Then, at the SQL prompt: `@/tmp/process_payment.sql`

**3. Start the service.**

```bash
mvn spring-boot:run
```

---

## Testing

```bash
mvn test
```

The TestNG suite is defined in `testng.xml` and covers the request validation and processing paths
described above.

---

## Current scope and what's next

This is a deliberately narrow slice — one endpoint, exercised end to end through a real database
rather than a mocked one, because the integration boundary is where this kind of service actually
breaks.

Planned next:

- [ ] GitHub Actions workflow running the build and test suite on every push
- [ ] Persisted idempotency store so repeat keys return the original response rather than reprocessing
- [ ] Structured request/response logging with correlation IDs
- [ ] OpenAPI specification generated from the controller

---

## Repository layout

```
src/
  main/java/com/example/paymentsapi/   — application code
  SQL/process_payment.sql              — authorisation stored procedure
pom.xml                                — Maven build
testng.xml                             — test suite definition
```