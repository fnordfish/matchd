# Development ideas

Currently Matchd follows a lazy approach when reading in configurations. The idea is to not instantiate the entire rules configuration on load, but only if needed.
For example, things like the Passthrough rule can evaluate system resolvers each time which makes reloading the service unnecessary. On the other hand, it needs to do this all the time.
Right now I'm uncertain about the performance implications, just let's see how well it works.
