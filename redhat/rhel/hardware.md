# get list of rhel hardware compatabiliy list

https://docs.google.com/spreadsheets/d/1rbvWpaNhuxRQh4CKwxsRfOPkoi400LPZEIeKpHk7jvg/edit#gid=1272334359

```bash
cat result.json | jq -r " .[] | [ .vendor, .hardware, .product ] | @csv " > result.csv

```



弯路

```bash
bash hardware.list.js > list

cat list | grep https | sed "s/^[[:space:]]*\'//g" | sed "s/\'.*$//g" | sort | uniq > list.uniq

curl -s https://access.redhat.com/ecosystem/hardware/959263 | grep breadcrumbs | sed "s/^<script>breadcrumbs = //g" | sed "s/;<\/script>$//g"


curl -s https://access.redhat.com/ecosystem/hardware/959263 | grep CertifiedVendorProduct

```
