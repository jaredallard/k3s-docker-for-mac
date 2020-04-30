# k3s Docker for Mac

Run k3s on Docker for Mac using host docker.

See: https://twitter.com/jaredallard/status/1249173858302689281

## Why?

 * sharing docker image cache with k3s, important for developer environments
 * naturally accessible ports on the host, thanks to it using host docker
 * more insight into kubernetes containers being run

## Usage

```bash
# To create a cluster
./up.sh

# To destroy a cluster
./destroy.sh
```

## Limitations

Persistence, i.e across Docker for Mac restarts hasn't really been tested.

## How it Works

We create a container (well, multiple) to allow for us to exec a command in the mount, ipc, uts, and pid namespace of the `dockerd` process. From here, we basically act like a virus and install the k3s binary into `/var/lib/k3s-dfm` directory and a few scripts to help start and cleanup itself.

k3s retains it's own network namespace, which we then use to expose ports using a TCP proxy that uses VPNKit under the hood (w/ the native Docker for Mac port-forwards) to bring k3s, and traefik, to the host (6443 k3s, 443 https-traefik, 80 http-traefik).

## Special Thanks

 * @malept - helped me work on making this much less hacky than it original was.
 * @ibuildthecloud - for making k3s :tada:

## License

MIT