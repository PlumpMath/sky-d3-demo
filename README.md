sky-d3-demo
===========

### Overview

An interactive data visualization using D3.js and the Sky database.
For more information on this demo, read the blog post:

[GitHub Archive Visualizer](http://skydb.io/blog/github-archive-visualizer.html)

If you have any problems setting it up, add an Issue to the GitHub page.


### Installation

To install, you'll need:

1. [Sky D3 Demo](https://github.com/skydb/sky-d3-demo)
1. [Sky](http://skydb.io/)
1. [Sky Ruby Client](https://github.com/skydb/sky.rb)
1. Set the path in your demo's `Gemfile` to your Sky Ruby client.
1. Run `bundle install`
1. Start the Sky server: `skyd`
1. Run `import.rb START_DATE END_DATE` to import data from the [GitHub Archive](http://www.githubarchive.org/).
1. Run `rackup` from your demo directory.
1. Go to http://localhost:4567

> NOTE: If you overwrite or delete the Sky database file then you'll need to restart Sky.


