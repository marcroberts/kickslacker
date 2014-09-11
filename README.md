kickslacker
===========

Post progress updates on a Kickstarter project to Slack

![](https://s3.amazonaws.com/f.cl.ly/items/3s381r2L1H103B0y0d0e/Image%202014-09-11%20at%2010.07.42%20am.png)

This is designed to be run on heroku, utilising the memcachier addon and the heroku scheduler to poll every 10 minutes.

Set your slack incoming webhook URL as a config variable called `SLACK_URL` and the room/group to post to in `SLACK_ROOM`, your kickstarter project as `KICKSTARTER_URL`. Schedule a task to run every 10 minutes `ruby poll.rb`
