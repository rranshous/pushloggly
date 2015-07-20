`docker build -t pushloggly .`
`docker run -it -v /var/run/docker.sock:/var/run/docker.sock pushloggly <token>`

alt you can use LOGGLY_TOKEN env var
`docker run -it -e LOGGLY_TOKEN=<token> -v /var/run/docker.sock:/var/run/docker.sock pushloggly`
