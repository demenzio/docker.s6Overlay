pipeline{
    agent{
        label "docker && linux"
    }
    environment { 
        distros = "alpine,debian"
        registry = "xuvin/s6overlay"
        registryCredential = 'docker-xuvin-cred'
        pushOverAPIUserKey = credentials('po-userkey')
        pushOverAPIAPPToken = credentials('jenkins-po-key')
        repoUSER = "just-containers"
        repoNAME = "s6-overlay"
        repoPATH = "${repoUSER}/${repoNAME}"
        newVersion = "PLACEHOLDER"
    }
    stages{
        stage("Clone"){
            steps{
                script{
                    newVersion = sh(label: 'Get Latest Release Version',script: 'curl --silent "https://api.github.com/repos/${repoPATH}/releases" | grep \'"tag_name":\' | sed -E \'s/.*"([^"]+)".*/\\1/\' | awk \'NR==1{print $1}\'', returnStdout: true).trim()
                }
                echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL} for Version ${newVersion}"
                // checkout scm
                git 'https://github.com/demenzio/docker.s6Overlay.git'
            }
            post{
                success{
                    echo "====> Clone - Success"
                }
                failure{
                    echo "====> Clone - Failure"
                }
            }
        }
        stage("Build"){
            steps{
                script{
                    distros.split(',').each {
                        sh (label: "Building Container ${registry}:${it}-${newVersion}", script: "docker build --pull --no-cache -f Dockerfile.${it} -t ${registry}:${it}-${newVersion} .")
                    }
                }
            }
            post{
                success{
                    echo "====> Build - Success"
                }
                failure{
                    echo "====> Build - Failure"
                }
            }
        }
        stage("Test"){
            steps{
                script{
                    distros.split(',').each {
                        sh (label: "Starting Test Container of ${registry}:${it}-${newVersion}", script: "docker run -it -d --name test-build${env.BUILD_ID}-s6-${it} ${registry}:${it}-${newVersion} /bin/sh")
                        sh (label: "Execute Test Command in ${registry}:${it}-${newVersion}", script: "docker exec test-build${env.BUILD_ID}-s6-${it} bash -c 'echo ContainerisRunning'")
                        //sh (label: "Stopping Test Container of ${registry}:${it}-${newVersion}", script: 'docker stop $(docker ps -q -a)')
                        sh (label: "Stopping Test Container of ${registry}:${it}-${newVersion}", script: "docker stop test-build${env.BUILD_ID}-s6-${it}")
                    }
                }            
            }
            post{
                cleanup{
                    //sh (label: "Removing Test Containers of ${registry}", script: 'docker rm $(docker ps -q -a)')
                    script{
                        distros.split(',').each {
                            sh (label: "Removing Test Containers of ${registry}", script: "docker rm -f test-build${env.BUILD_ID}-s6-${it}")
                        }
                    }                  
                }
                success{
                    echo "====> Test - Passed"
                }
                failure{
                    echo "====> Test - Failure"
                }
        
            }
        }
        stage("Push"){
            steps{
                script{
                    distros.split(',').each {
                        docker.withRegistry( '', 'docker-xuvin-cred' ) {
                            sh (label: "Tagging ${registry}:${it}-${newVersion} as latest", script: "docker tag ${registry}:${it}-${newVersion} ${registry}:${it}-latest")
                            //sh (label: "Pushing ${registry}:${it}-${newVersion} to Docker Hub", script: "docker push ${registry}:${it}-${newVersion}")
                            sh (label: "Pushing ${registry}:${it}-${newVersion} as latest to Docker Hub", script: "docker push ${registry}:${it}-${newVersion} && docker push ${registry}:${it}-latest")
                        }
                    }
                }
            }
            post{
                success{
                    echo "====> Push - Success"
                }
                failure{
                    echo "====> Push - Failure"
                }
            }
        }
        stage("Clean Up"){
            steps{
                //sh (label: 'Remove Created Docker Images', script: 'docker rmi -f $(docker images -aqf "reference=${registry}")')
                script{
                distros.split(',').each {
                sh (label: "Removing Created Docker Images with Tag ${registry}:${it}-${newVersion}", script: "docker rmi -f ${registry}:${it}-${newVersion} && docker rmi -f ${registry}:${it}-latest || exit 0")
                }
                sh (label: "Cleaning Docker Environment", script: "yes | docker system prune")
            }
            }
            post{
                success{
                    echo "====> Cleaned Up - Success"
                }
                failure{
                    echo "====> Cleaned up - Failure"
                }
            }
        }
    }
    post{
        success{
            sh (label: 'Sending Notification with Status 0', script: 'curl -s --form-string "token=${pushOverAPIAPPToken}" --form-string "user=${pushOverAPIUserKey}" --form-string "priority=0" --form-string "title=${registry} - Status 0" --form-string "message=Build for ${registry} - Completed" https://api.pushover.net/1/messages.json', returnStdout: true)
        }
        failure{
            sh (label: 'Sending Notification with Status 2', script: 'curl -s --form-string "token=${pushOverAPIAPPToken}" --form-string "user=${pushOverAPIUserKey}" --form-string "priority=2" --form-string "retry=30" --form-string "expire=10800" --form-string "title=${registry} - Status 2" --form-string "message=Build for ${registry} - Failure" https://api.pushover.net/1/messages.json', returnStdout: true)
            //sh (label: "Removing all created images of ${registry}", script: 'docker rmi $(docker images -aqf "reference=${registry}") || exit 0')
            script{
                distros.split(',').each {
                sh (label: "Removing all created images of ${registry}:${it}-${newVersion}", script: "docker rmi -f ${registry}:${it}-${newVersion} && docker push docker rmi -f ${registry}:${it}-latest || exit 0")
                }
            }
            sh (label: "Cleaning Docker Environment", script: "yes | docker system prune")
        }
        aborted{
            sh (label: 'Sending Notification with Status 1', script: 'curl -s --form-string "token=${pushOverAPIAPPToken}" --form-string "user=${pushOverAPIUserKey}" --form-string "priority=1" --form-string "title=${registry} - Status 1" --form-string "message=Build for ${registry} - Aborted" https://api.pushover.net/1/messages.json', returnStdout: true)
            //sh (label: "Removing all created images of ${registry}", script: 'docker rmi $(docker images -aqf "reference=${registry}") || exit 0')
            script{
                distros.split(',').each {
                sh (label: "Removing all created images of ${registry}:${it}-${newVersion}", script: "docker rmi -f ${registry}:${it}-${newVersion} && docker rmi -f ${registry}:${it}-latest || exit 0")
                }
            }
            sh (label: "Cleaning Docker Environment", script: "yes | docker system prune")
        }
    }
}