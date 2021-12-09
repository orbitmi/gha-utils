module.exports = ({github, context}) => {
    if (context.eventName == "pull_request") {
        const { issue: { number: issue_number }, repo: { owner, repo }  } = context;
        const body = decodeURI("👋 Hey! ${{ env.REPO_SUMMARY }}");
        github.rest.issues.createComment({ issue_number, owner, repo, body });
    } else {
        console.log("Not a PR")
    }
}