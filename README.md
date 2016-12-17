# Rollbar::Dumps

Install `bundler` if not present.

```shell
gem install bundler
```

Installation:

```shell
bundle install
```

Testing the sample.c example:

```shell
gcc -g sample.c -o sample
./sample
ROLLBAR_ACCESS_TOKEN=your-token-here bundle exec ruby bin/run ./sample ./core
```
