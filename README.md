# dockerized-dashboard
A dockerized dashboard for developing dashboard components locally.

# How to build and run a local dashboard
1. Install docker locally
1. From the root of this repo, run `docker build -t dashboard .`. This will build the docker container.
1. To start the dashboard, run `docker run -d -p 8080:3030 dashboard`. The dashboard is now available in your web browser via http://localhost:8080.

# How to get the SonarQube widget working
1. The widget queries a local SonarQube service running on port 9000. Therefore, run `docker run -d --name sonarqube -p 9000:9000 sonarqube` in order to stand up that service. SonarQube is now available in your web browser at http://localhost:9000. Login to the SonarQube using the default username/password combination of admin/admin.
2. The dashboard still needs to know the network address for this SonarQube instance. Run `docker network inspect bridge`, find the container named sonarqube and note its IPv4Address.
3. Edit jobs/sonar.rb and change the value for bridge_network_sq_ip to the IPv4Address value from the previous step.
4. Rebuild and re-run the dashboard container. The widget should now display the "Health" value of "GREEN".
