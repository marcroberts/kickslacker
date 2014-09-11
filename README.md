kickslacker
===========

Post progress updated on a kickstart project to Slack

This is designed to be run on heroku, utilising the memcachier addon and the heroku scheduler to poll every 10 minutes.

Set your slack incoming webhook URL as a config variable called `SLACK_URL` and the room/group to post to in `SLACK_ROOM`, your kickstarter project as `KICKSTARTER_URL`. Schedule a task to run every 10 minutes `ruby poll.rb`
