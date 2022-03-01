const fs = require('fs')

module.exports = ({github, context, pr_msg}) => {
  if (context.eventName == "pull_request") {
    let body
    const {issue: {number: issue_number}, repo: {owner, repo}} = context;
    if (pr_msg.startsWith('file::')) {
      body = fs.readFileSync(pr_msg.split('::')[1], 'utf8')
    } else {
      body = decodeURI(`👋 Hey!\n ${pr_msg}`);
    }

    github.rest.issues.createComment({issue_number, owner, repo, body});
  } else {
    console.log("Not a PR")
  }
}
