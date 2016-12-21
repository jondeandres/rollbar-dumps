# Rollbar core dumps notifier

Install the package:

```shell
go get github.com/jondeandres/rollbar-dumps
```

Testing the sample.c in `./example` directory:

```shell
cd example
gcc -g sample.c -o sample
ulimit -c unlimited
./sample
ROLLBAR_ACCESS_TOKEN=your-token-here rollbar-dumps sample core
```
