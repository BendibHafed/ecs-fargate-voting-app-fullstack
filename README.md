# Vote App - DevOps Playground
This project is a lightweight fullstack voting application designed as a hands-on DevOps lab. It combines a simple HTML + JavaScript frontend, a Flask backend, and a SQLite database to simulate a voting system — all deployed on AWS using ECS Fargate.

The goal is not the app itself, but the infrastructure around it: containerization, CI/CD pipelines, infrastructure as code, and cloud-native deployment strategies. It’s built to demonstrate clean architecture, session-based authentication, and reproducible workflows — ideal for learners and engineers exploring modern DevOps practices.

Users can register, log in, view polls, and cast votes. The app is modular, maintainable, and intentionally minimal to keep the focus on automation, deployment, and infrastructure clarity.

## Objective
Deploy a simple Voting App to explore CI/CD, IaC, ECS, etc.

## Architecture
- Frontend using HTML + Jinja2 + JS: Dynamic rendering, user interaction.
- Backend using Flask (Blueprints) + SQLAlchemy: Routing, session management, ORM.
- Database:	SQLite (local) / PostgreSQL (prod)	Persistent storage for users, polls, votes.
- Authentication: Session-based, Simple login/logout with hashed passwords.
- CI/CD	ACT (local) + GitHub Actions: Automated testing, linting, deployment

## Local Setup & Running
### 1. Clone the repo
```
$ git clone https://github.com/BendibHafed/ecs-fargate-voting-app-fullstack.git
$ cd ecs-fargate-voting-app-fullstack
```
### 2. Create virtual environment
```
$ python -m venv myEnv
$ source myEnv/bin/activate
$ pip install -r .backend/requirements.txt
```
### 3. Create and Apply Migration
Initialize the Database:
```
$ cd backend
$ flask db init
$ flask db migrate -m "Initial schema"
$ flask db upgrade
```
This creates all tables based on models.py
### 4. Seed the databse
Return back to the root directory:
```
$ cd ../
$ python -m backend.seed
```
### 5. Run the Flask Server
```
$ python -m backend.run
```
Open the browser at:
'''http://localhost:5000/```

A landing page : <i>index.html</i> appears
Login and register forms
## AWS Deployment
### Infrastructure Architecture (Decoupled Frontend + Cognito + ECS)

###  Request Flow

- **User Browser**
  - Sends request to CloudFront CDN

- **CloudFront + S3**
  - Serves static frontend (HTML/JS)
  - Redirects to Cognito for login/signup

- **Cognito Hosted UI**
  - Authenticates user
  - Returns JWT token to browser

- **JWT Token**
  - Stored in browser (localStorage or cookie)
  - Sent with API requests via `Authorization: Bearer <token>`

- **Application Load Balancer (ALB)**
  - Routes traffic to Flask API on ECS Fargate
  - Handles TLS termination and health checks

- **ECS Fargate: Flask API**
  - Stateless containerized backend
  - Validates JWT and processes requests

- **RDS (PostgreSQL)**
  - Stores users, polls, and votes

- **IAM Role for ECS Task Execution**
  - Grants access to secrets, logs, and other AWS resources

---

## CI/CD
links to: <br>
`.github/workflows/ci.yml`
`.github/workflows/cd.yml`

## Tests & Simulation
- using `act` for local CI/CD emulation
- Unit tests

