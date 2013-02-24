# switch_redis

Redis is an amazingly useful datastore.  This script automates the 
steps necessary to manually failover from a bad master to a slave.
You still have to manually decide when to failover but this script does
all the hard work for you in order to minimize the risk of screwing
something up at 3 AM when it blows up.

We tried fully automated solutions like `redis_failover` but found that
the complexity it introduced into our production system was more than we
were comfortable with.  I prefer the simplicity of this approach for
now.  YMMV.

## Installation

Still trying to figure out the best way to customize and distribute a
script.  Is this a Rubygem?  A clonable git repo?  Would love to hear
ideas or, better yet, PRs which improve this.

## How it works

`adapter.rb` contains a generic series of steps required to failover.
You create a subclass which customizes the steps as necessary for your
production environment.  You can include `credentials.rb` in the same
directory to load sensitive info like passwords for 3rd party services.
An example adapter is included which we use at The Clymb.

## Credit

Thank you to [The Clymb](http://theclymb.com/invite-from/mperham) for allowing me to open source this work.

## Author

Mike Perham, @mperham.  Thanks to @ckuttruff for the inspiration.
