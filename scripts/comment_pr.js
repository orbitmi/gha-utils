module.exports = ({github, context, pr_msg}) => {
    if (context.eventName == "pull_request") {
        const { issue: { number: issue_number }, repo: { owner, repo }  } = context;
        const body = decodeURI('👋 Hey!\n'+pr_msg);
        github.rest.issues.createComment({ issue_number, owner, repo, body });
    } else {
        console.log("Not a PR")
    }
}