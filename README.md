# dockerized-dashboard
This repository contains code for a dockerized dashboard (using the Smashing dashboard framework) for developing dashboard components locally.

Currently, the dashboard contains sample widgets to display information from SonarQube and Rally.

![Sample Dashboard](./sampledashboard.png)

# How to build and run a local dashboard
1. Install docker locally.
1. From the root of this repo, run `docker build -t dashboard .`. This will build the docker container.
1. To start the dashboard, run `docker run -d -p 8080:3030 dashboard`. The dashboard is now available in your web browser via http://localhost:8080.

# How to get the SonarQube widget working
1. The widget queries a local SonarQube service running on port 9000. Therefore, run `docker run -d --name sonarqube -p 9000:9000 sonarqube` in order to stand up that service. SonarQube is now available in your web browser at http://localhost:9000. You may login to the SonarQube using the default username/password combination of admin/admin, but it is not required to connect the dashboard to SonarQube.

   The widget's background should eventually change to the default widget background, currently a solid (no flashing) light blue. This indicates a healthy connection to SonarQube. Unhealthy connections will change the background to use the style `status-warning` or `status-danger` as defined in the default CSS. These styles usually include "alarming" colors like red and yellow, and include a flashing behavior to grab the user's attention.

   If, after a few minutes, the widget's background does not change, continue to the next step.
1. The dashboard still needs to know the network address for this SonarQube instance. Run `docker network inspect bridge`, find the container named sonarqube and note its IPv4Address.
1. Edit `smashing/jobs/sonar.rb` and change the value for bridge_network_sq_ip to the IPv4Address value from the previous step.
1. Rebuild and re-run the dashboard container. The Sonar widget should display with the default background.

# How to get the SonarQube widget to actually display something useful for a Gradle project
1. If you don't have Gradle installed locally, install it. Basic guidance is available at https://spring.io/guides/gs/gradle/#initial.
1. If you don't have a Gradle project already:
  1. Fork a simple one at https://github.com/spring-guides/gs-gradle.git.
  1. Clone it locally via something like `git clone https://github.com/spring-guides/gs-gradle.git`.
  1. `cd gs-gradle/complete` directory within the repo to use the project located in that directory. (h/t to https://spring.io/guides/gs/gradle/ for basic guidance).
1. In your project, edit `build.gradle` to include the following at the top of the file:

        plugins {
            id "org.sonarqube" version "2.7"
        }

        apply plugin: 'jacoco'

1. Run `gradle test jacocoTestReport sonarqube --no-daemon`. This creates a test coverage report and feeds it to SonarQube using the SonarQube Scanner for Gradle (https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner+for+Gradle).
1. In SonarQube, confirm a new project has been created to analyze the Gradle project. Browse to the project and then to the Administration tab. Select Update Key and copy the key. Back in the dashboard code, edit `smashing/jobs/sonar.rb` and replace the value of `sq_project_key` with the project key from SonarQube.
1. Rebuild and re-run the dashboard container. The widget should now display useful information about the Gradle project.

# How to get the Rally widget working
1. Copy `smashing/widgets/rally/rally.credentials.template` to `smashing/widgets/rally/rally.credentials` and change the username and password in that file to use valid Rally credentials.
1. Edit jobs/rally.rb and replace the value of `rally_project_key` with the project key from Rally. The project key can be found in the URL for the project homepage, i.e. https://rally1.rallydev.com/#/THIS_IS_MY_PROJECT_KEY.
1. Rebuild and re-run the dashboard container. The widget's background should eventually change to the default widget background, currently a solid (no flashing) light blue. This indicates a healthy connection to Rally. Unhealthy connections will change the background to use the style `status-warning` or `status-danger` as defined in the default CSS. These styles usually include "alarming" colors like red and yellow, and include a flashing behavior to grab the user's attention.



# How to get the Jenkins widget working
NOTE: Before proceeding, consider increasing the Docker Engine's available memory. On the Mac, increasing from the 2GB default to 4GB was necessary to run SonarQube and Jenkins simultaneously.

1. Start Jenkins in a Docker container with `docker run -d -p 8090:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts`.
This will create a 'jenkins_home' Docker volume on the host machine that will survive the container stop/restart/deletion. You can access the volume via `docker volume ls`.

   NOTE FOR MAC USERS: The `jenkins_home` volume on the docker host lives inside of a Docker VM. To access it, try `screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty`, then once inside the screen program, press Enter, then `cd /var/lib/docker/volumes`. You will see the directory  there. Exit the screen program with Ctrl+A, then `k` to kill the session.

1. Setup Jenkins.
   1. In your web browser, navigate to Jenkins at http://localhost:8090. It will provide instructions about where to find the administrator password inside of the running container, and provide a form field to enter that password in order to continue setup.
   1. Run `docker ps -a` to find the ID of the running Jenkins container.
   1. Run `docker exec -i -t <YOUR_CONTAINER_ID_HERE> cat <YOUR_INITIAL_ADMIN_PASSWORD_LOCATION>`, replacing `<YOUR_CONTAINER_ID_HERE>` with the container ID obtained in the last step and `<YOUR_INITIAL_ADMIN_PASSWORD_LOCATION>` with the location of the admin password file obtained above. This will display the admin password. Copy it and paste it back in the Jenkins form in your browser.
   1. When prompted to Customize Jenkins, select Install suggested plugins. Setup will continue. Monitor the progress.
   1. On the next screen, click Continue as admin.
   1. On the next screen, confirm the default URL by clicking on Save and Finish.
   1. On the next screen, click the Start using Jenkins button.

      NOTE: You may need to restart the Jenkins container.

   1. Login to Jenkins as the admin user using the password obtained above.
   1. Go to Manage Jenkins, Configure Global Security, and un-check the Enable security checkbox.
   1. In Jenkins, go to Manage Jenkins, Configure System. Under Global properties, check the Environment Variables checkbox and click the resulting Add button to add an environment variable, Add an environment variable with the name of `sonarqube_url` and value of `http://172.17.0.1:9000`. Click the Save button.
1. Setup a Jenkins job.
   1. In the lefthand menu, click New Item to create a new job. Name the job and select Multibranch Pipeline. Click OK.
   1. On the next screen:
      1. Supply a display name
      1. Under Branch Sources, click Add source. Select GitHub.
      1. Click Add next to Credentials, select Jenkins off the resulting Provider menu.
      1. In the window, add credentials for username and password. Use your GitHub username and a GitHub Personal Access Token as the password. The Persoanl Access Token should have the `repo` and `admin:repo_hook` scopes enabled.
      1. Back on the job configuration screen, select the credential just added.
      1. In the Owner field, enter your GitHub user. Click the Repository drop down and select your repository. This may take some time if there are many repositories.
      1. Under Behaviors, remove "Discover pull requests from forks".
      1. Click Save. It'll scan and find your repo and branch. Unless you have a Jenkinsfile, it should result in nothing being built.
1. If your repo has no Jenkinsfile, add a file named `Jenkinsfile` to the root of the repo with the following:

        pipeline {
            agent any
            stages {
              stage('Unit & Integration Tests') {
                  steps {
                      script {
                          dir ('complete') {
                            try {
                                sh './gradlew test jacocoTestReport sonarqube -Dsonar.host.url=${sonarqube_url}  --no-daemon'
                            } finally {
                                echo 'Successfully ran something!'
                            }
                          }
                      }
                  }
              }
            }
        }

1. Install the Gradle wrapper in the root of your repo if it is not already present by running `gradle wrapper`.
1. Commit local code changes, adding files if necessary.
1. In Jenkins, go to the multibranch pipeline previously created and click Scan Repository Now. The newly committed Jenkinsfile should be recognized by Jenkins and it will execute. Click into the branch and job to watch the progress. Eventually, it should report success. In SonarQube, the results of the project scan should be present shortly.
1. In Jenkins, go to the branch page under the multibranch pipeline job. Note the URL of this page, especially the part after the first `/job`, e.g., `complete/job/master`. In the dashboard code, edit `jenkins_build.rb`, modifying the line

        'JOB' => { :job => 'BUILD', :pre_job => 'PRE_BUILD'}

   to be something like
        'job1' => { :job => '<MULTIBRANCH_PIPELINE_BRANCH_URL>'}

   where `<MULTIBRANCH_PIPELINE_BRANCH_URL>` is the part of the URL mentioned above.

1. Run `docker inspect network bridge`. Find the Jenkins IP address. In the dashboard code, edit `jenkins_build.rb`, modifying the line

        JENKINS_URI = URI.parse("http://localhost:8090")

   to be something like
        JENKINS_URI = URI.parse("http://<JENKINS_IP>:8080")

    where `<JENKINS_IP>` is the Jenkins IP address. Note the port is changed from 8090 to 8080.

1. Rebuild and re-run the dashboard container. The SonarQube widget should report healthy and display code quality stats. The Jenkins widget should report healthy and the background color should be green, assuming the Jenkins run above was successful. You can test Jenkins connectivity by going to Jenkins, re-running the build job, then quickly coming back to the dashboard. While the Jenkins job is running, the widget should have a grey background color, and the meter should indicate progress of the running build. Eventually, the widget background should turn green if successful, red if failed.

# How to get the Sumo Logic widget working
1. Copy `smashing/widgets/sumologic/sumologic.credentials.template` to `smashing/widgets/sumologic/sumologic.credentials` and change the API access ID and key in that file to use valid Sumo Logic API credentials.
1. Rebuild and re-run the dashboard container. The widget's background should eventually change to the default widget background, currently a solid (no flashing) light blue. This indicates a healthy connection to Sumo Logic. Unhealthy connections will change the background to use the style `status-warning` or `status-danger` as defined in the default CSS. These styles usually include "alarming" colors like red and yellow, and include a flashing behavior to grab the user's attention.

# Reference
* Smashing: https://smashing.github.io
* SonarQube latest documentation: https://docs.sonarqube.org/latest/
* JaCoCo basic tutorial: https://www.ratanparai.com/java/java-application-using-gradle-with-code-coverage/
* Rally Web Services API: https://rally1.rallydev.com/slm/doc/webservice/
* Jenkins Docker documentation: https://github.com/jenkinsci/docker/blob/master/README.md
* Jenkins widget: https://gist.github.com/mavimo/6334816
* Sumo Logic APIs: https://help.sumologic.com/APIs
