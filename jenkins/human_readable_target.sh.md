## human_readable_target.sh
This script adds a set of tools which can be used to query a target system for the current commit, and return some pertinent information about the changes so that a human_readable set of information about what's on the target is available in the jenkins job description.
In the `Generate environment variables from script` section of the Jenkins job
```bash
source <repo-root>/tools/jenkins/human_readable_target.sh
EDITOR_INFO=$(human_readable_target ${TARGET})
```
And in the `Set Build Name` section of the job you can create a Build Name of `#${BUILD_NUMBER}_${EDITOR_INFO}`

The job name will contain the job number followed by a "branch guess" followed by the hash of the last commit which is running in the editor.
