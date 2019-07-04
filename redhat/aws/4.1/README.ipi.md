#

```bash

rm -rf conf

mkdir -p conf

./openshift-install create cluster --dir=conf  --log-level debug

./openshift-install destroy cluster --dir=conf --log-level=debug

```