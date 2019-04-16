# dockerized-dashboard
A dockerized dashboard for developing dashboard components locally.

# How to build and run a local dashboard
1. Install docker locally
1. From the root of this repo, run `docker build -t dashboard .`. This will build the docker container.
1. To start the dashboard, run `docker run -d -p 8080:3030 dashboard`. The dashboard is now available in your web browser via http://localhost:8080.
