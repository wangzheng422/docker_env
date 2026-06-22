#!/usr/bin/env python
"""External RHCL GLB controller for the three-cluster lab.

This controller is intentionally implemented with ssh + oc because the lab
keeps one kubeconfig per helper user on the AWS helper host.  It can run from
the local workstation or from the helper host itself.

Supported actions:
- read RHCL DNSHealthCheckProbe health per cluster
- publish DNS Groups active-groups TXT to every cluster's Kuadrant CoreDNS
- optionally set unhealthy clusters' DNSPolicy weight to 0 and restore healthy
  clusters to their configured base weight
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as dt
import ipaddress
import json
import os
import shlex
import subprocess
import sys
import time
from typing import Sequence


DEFAULT_ACTIVE_GROUPS_FQDN = "kuadrant-active-groups.glb.kuadrant.wzhlab.top."
DEFAULT_COREDNS_NAMESPACE = "kuadrant-coredns"
DEFAULT_COREDNS_CONFIGMAP = "kuadrant-coredns"
DEFAULT_DNSPOLICY_NAMESPACE = "api-gateway"
DEFAULT_DNSPOLICY_NAME = "ingress-gateway-dns"
DEFAULT_PROBE_NAMESPACE = "api-gateway"
DEFAULT_PROBE_OWNER = "ingress-gateway-http"


@dataclasses.dataclass(frozen=True)
class Cluster:
    group: str
    helper_user: str
    base_weight: int
    geo: str | None = None
    default_geo: bool | None = None
    coredns_namespace: str = DEFAULT_COREDNS_NAMESPACE
    coredns_configmap: str = DEFAULT_COREDNS_CONFIGMAP
    dnspolicy_namespace: str = DEFAULT_DNSPOLICY_NAMESPACE
    dnspolicy_name: str = DEFAULT_DNSPOLICY_NAME
    probe_namespace: str = DEFAULT_PROBE_NAMESPACE
    probe_owner: str = DEFAULT_PROBE_OWNER


@dataclasses.dataclass
class CommandResult:
    argv: list[str]
    returncode: int
    stdout: str
    stderr: str

    def ok(self) -> bool:
        return self.returncode == 0


@dataclasses.dataclass
class ClusterHealth:
    cluster: Cluster
    healthy: bool
    reason: str
    probe_names: list[str]
    result: CommandResult


def now_utc() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def dns_serial() -> int:
    return int(dt.datetime.now(dt.timezone.utc).timestamp())


def run(argv: Sequence[str], timeout: int, dry_run: bool = False) -> CommandResult:
    argv = list(argv)
    if dry_run:
        return CommandResult(argv=argv, returncode=0, stdout="", stderr="DRY_RUN")
    completed = subprocess.run(
        argv,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    return CommandResult(
        argv=argv,
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )


def remote_oc(helper: str, cluster: Cluster, oc_args: Sequence[str], timeout: int, dry_run: bool) -> CommandResult:
    oc_command = " ".join(shlex.quote(part) for part in ["oc", *oc_args])
    if helper in ("", "local", "localhost"):
        return run(["su", "-", cluster.helper_user, "-c", oc_command], timeout=timeout, dry_run=dry_run)
    remote = f"su - {cluster.helper_user} -c {shlex.quote(oc_command)}"
    return run(["ssh", helper, remote], timeout=timeout, dry_run=dry_run)


def log(message: str) -> None:
    print(f"{now_utc()} {message}", flush=True)


def print_result(label: str, result: CommandResult) -> None:
    quoted = " ".join(shlex.quote(part) for part in result.argv)
    log(f"{label} command={quoted}")
    log(f"{label} returncode={result.returncode}")
    if result.stdout:
        print(result.stdout.rstrip(), flush=True)
    if result.stderr:
        print(result.stderr.rstrip(), file=sys.stderr, flush=True)


def parse_cluster(raw: str) -> Cluster:
    parts = raw.split(":")
    if len(parts) not in (3, 5):
        raise argparse.ArgumentTypeError("cluster must be GROUP:HELPER_USER:BASE_WEIGHT or GROUP:HELPER_USER:BASE_WEIGHT:GEO:DEFAULT_GEO")
    group, helper_user, weight_raw = parts[:3]
    try:
        base_weight = int(weight_raw)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("BASE_WEIGHT must be an integer") from exc
    if base_weight < 0:
        raise argparse.ArgumentTypeError("BASE_WEIGHT must be >= 0")
    geo = None
    default_geo = None
    if len(parts) == 5:
        geo = parts[3] or None
        default_raw = parts[4].lower()
        if default_raw not in ("true", "false"):
            raise argparse.ArgumentTypeError("DEFAULT_GEO must be true or false")
        default_geo = default_raw == "true"
    return Cluster(group=group, helper_user=helper_user, base_weight=base_weight, geo=geo, default_geo=default_geo)


def parse_policy_ref(raw: str) -> tuple[str, str, str]:
    parts = raw.split(":")
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("policy ref must be HELPER_USER:NAMESPACE:NAME")
    return parts[0], parts[1], parts[2]


def load_policy_from_crd(args: argparse.Namespace) -> None:
    if not args.policy_crd:
        return

    helper_user, namespace, name = args.policy_crd
    policy_cluster = Cluster("policy-source", helper_user, 0)
    result = remote_oc(
        args.helper,
        policy_cluster,
        [
            "get",
            "globaltrafficpolicy.rhcl-lab.wzhlab.top",
            name,
            "-n",
            namespace,
            "-o",
            "json",
            "--request-timeout=20s",
        ],
        timeout=args.timeout,
        dry_run=args.dry_run,
    )
    print_result("load-policy-crd", result)
    if not result.ok():
        raise RuntimeError(f"failed to load policy CRD {namespace}/{name}")
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"failed to parse policy CRD {namespace}/{name} as JSON") from exc

    spec = payload.get("spec", {})
    args.active_groups_fqdn = spec.get("activeGroupsFQDN", args.active_groups_fqdn)
    args.ttl = int(spec.get("ttl", args.ttl))

    strategies = spec.get("strategies")
    if strategies:
        args.strategy = list(strategies)

    sites = spec.get("sites", [])
    if sites:
        args.cluster = [
            Cluster(
                group=str(site["group"]),
                helper_user=str(site["helperUser"]),
                base_weight=int(site.get("baseWeight", 0)),
                geo=str(site["geo"]) if "geo" in site else None,
                default_geo=bool(site["defaultGeo"]) if "defaultGeo" in site else None,
                coredns_namespace=str(site.get("corednsNamespace", DEFAULT_COREDNS_NAMESPACE)),
                coredns_configmap=str(site.get("corednsConfigMap", DEFAULT_COREDNS_CONFIGMAP)),
                dnspolicy_namespace=str(site.get("dnsPolicyNamespace", DEFAULT_DNSPOLICY_NAMESPACE)),
                dnspolicy_name=str(site.get("dnsPolicyName", DEFAULT_DNSPOLICY_NAME)),
                probe_namespace=str(site.get("probeNamespace", DEFAULT_PROBE_NAMESPACE)),
                probe_owner=str(site.get("probeOwner", DEFAULT_PROBE_OWNER)),
            )
            for site in sites
        ]


def load_json_file(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return payload


def select_geo_rule(geo_source: dict, client_ip: str) -> dict | None:
    address = ipaddress.ip_address(client_ip)
    selected: tuple[int, dict] | None = None
    for rule in geo_source.get("clientGeo", []):
        network = ipaddress.ip_network(str(rule["cidr"]), strict=False)
        if address in network:
            prefixlen = network.prefixlen
            if selected is None or prefixlen > selected[0]:
                selected = (prefixlen, rule)
    return selected[1] if selected else geo_source.get("default")


def apply_geo_source(active: list[str], args: argparse.Namespace) -> list[str]:
    if not args.geo_source:
        return active
    if not args.client_ip:
        raise ValueError("--client-ip is required when --geo-source is set")

    source = load_json_file(args.geo_source)
    rule = select_geo_rule(source, args.client_ip)
    if not rule:
        log(f"geo-decision client_ip={args.client_ip} rule=none active_groups={'&&'.join(active)}")
        return active

    preferred = [str(group) for group in rule.get("preferredGroups", [])]
    filtered = [group for group in active if group in preferred]
    if not filtered and not args.geo_allow_empty:
        log(
            "geo-decision "
            f"client_ip={args.client_ip} geo={rule.get('geo', '-')} "
            f"preferred={'&&'.join(preferred) or '-'} matched_healthy=none "
            f"fallback={'&&'.join(active)}"
        )
        return active

    log(
        "geo-decision "
        f"client_ip={args.client_ip} geo={rule.get('geo', '-')} "
        f"cidr={rule.get('cidr', 'default')} "
        f"preferred={'&&'.join(preferred) or '-'} "
        f"selected={'&&'.join(filtered)}"
    )
    return filtered


def mock_health(args: argparse.Namespace) -> list[ClusterHealth] | None:
    if not args.mock_healthy_groups:
        return None
    healthy_groups = {group.strip() for group in args.mock_healthy_groups.split(",") if group.strip()}
    result = CommandResult(["mock-health", ",".join(sorted(healthy_groups))], 0, "MOCK_HEALTH", "")
    return [
        ClusterHealth(
            cluster=cluster,
            healthy=cluster.group in healthy_groups,
            reason="mock-healthy" if cluster.group in healthy_groups else "mock-unhealthy",
            probe_names=[f"mock-{cluster.group}"],
            result=result,
        )
        for cluster in args.cluster
    ]


def get_probe_health(helper: str, cluster: Cluster, timeout: int, dry_run: bool) -> ClusterHealth:
    result = remote_oc(
        helper,
        cluster,
        [
            "get",
            "dnshealthcheckprobe",
            "-n",
            cluster.probe_namespace,
            "-l",
            f"kuadrant.io/health-probes-owner={cluster.probe_owner}",
            "-o",
            "json",
            "--request-timeout=20s",
        ],
        timeout=timeout,
        dry_run=dry_run,
    )
    if not result.ok():
        return ClusterHealth(cluster, False, "probe-read-error", [], result)
    try:
        payload = json.loads(result.stdout or "{}")
    except json.JSONDecodeError:
        return ClusterHealth(cluster, False, "probe-json-error", [], result)

    items = payload.get("items", [])
    if not items:
        return ClusterHealth(cluster, False, "probe-missing", [], result)

    names: list[str] = []
    values: list[bool] = []
    for item in items:
        names.append(item.get("metadata", {}).get("name", "<unknown>"))
        values.append(bool(item.get("status", {}).get("healthy", False)))

    if all(values):
        return ClusterHealth(cluster, True, "all-probes-healthy", names, result)
    return ClusterHealth(cluster, False, "one-or-more-probes-unhealthy", names, result)


def active_groups_zone(fqdn: str, groups: Sequence[str], ttl: int) -> str:
    group_value = "&&".join(groups)
    return (
        f"{fqdn} {ttl} IN SOA ns1. hostmaster. {dns_serial()} 7200 3600 1209600 {ttl}\n"
        f"{fqdn} {ttl} IN NS ns1.\n"
        f'{fqdn} {ttl} IN TXT "version=1;groups={group_value}"\n'
    )


def patch_active_groups(
    helper: str,
    cluster: Cluster,
    fqdn: str,
    active_groups: Sequence[str],
    ttl: int,
    timeout: int,
    dry_run: bool,
) -> CommandResult:
    payload = {
        "data": {
            "active-groups.db": active_groups_zone(fqdn, active_groups, ttl),
        }
    }
    return remote_oc(
        helper,
        cluster,
        [
            "patch",
            "configmap",
            cluster.coredns_configmap,
            "-n",
            cluster.coredns_namespace,
            "--type",
            "merge",
            "-p",
            json.dumps(payload),
            "--request-timeout=20s",
        ],
        timeout=timeout,
        dry_run=dry_run,
    )


def patch_dnspolicy_weight(
    helper: str,
    cluster: Cluster,
    weight: int,
    timeout: int,
    dry_run: bool,
) -> CommandResult:
    load_balancing: dict[str, object] = {"weight": weight}
    if cluster.geo is not None:
        load_balancing["geo"] = cluster.geo
    if cluster.default_geo is not None:
        load_balancing["defaultGeo"] = cluster.default_geo
    patch = {"spec": {"loadBalancing": load_balancing}}
    return remote_oc(
        helper,
        cluster,
        [
            "patch",
            "dnspolicy",
            cluster.dnspolicy_name,
            "-n",
            cluster.dnspolicy_namespace,
            "--type",
            "merge",
            "-p",
            json.dumps(patch),
            "--request-timeout=20s",
        ],
        timeout=timeout,
        dry_run=dry_run,
    )


def reconcile(args: argparse.Namespace) -> int:
    health = mock_health(args)
    if health is None:
        health = [get_probe_health(args.helper, cluster, args.timeout, args.dry_run) for cluster in args.cluster]

    for item in health:
        log(
            "health "
            f"group={item.cluster.group} user={item.cluster.helper_user} "
            f"healthy={item.healthy} reason={item.reason} probes={','.join(item.probe_names) or '-'}"
        )
        if args.verbose:
            print_result(f"probe group={item.cluster.group}", item.result)

    active = [item.cluster.group for item in health if item.healthy]
    try:
        active = apply_geo_source(active, args)
    except (OSError, ValueError, KeyError) as exc:
        print(f"failed to apply geo source: {exc}", file=sys.stderr)
        return 1

    if not active and not args.allow_empty:
        log("refuse_empty_active_groups=true keep_previous_state=true")
        return 2

    if "active-groups" in args.strategy:
        log(f"strategy=active-groups groups={'&&'.join(active)}")
        for cluster in args.cluster:
            result = patch_active_groups(
                args.helper,
                cluster,
                args.active_groups_fqdn,
                active,
                args.ttl,
                args.timeout,
                args.dry_run,
            )
            print_result(f"patch-active-groups group={cluster.group}", result)
            if not result.ok():
                return result.returncode

    if "dnspolicy-weight" in args.strategy:
        log("strategy=dnspolicy-weight unhealthy_weight=0")
        healthy_by_group = {item.cluster.group: item.healthy for item in health}
        for cluster in args.cluster:
            desired_weight = cluster.base_weight if healthy_by_group.get(cluster.group, False) else 0
            result = patch_dnspolicy_weight(args.helper, cluster, desired_weight, args.timeout, args.dry_run)
            print_result(
                "patch-dnspolicy-weight "
                f"group={cluster.group} geo={cluster.geo or '-'} "
                f"defaultGeo={cluster.default_geo if cluster.default_geo is not None else '-'} "
                f"desired_weight={desired_weight}",
                result,
            )
            if not result.ok():
                return result.returncode

    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="RHCL GLB external controller")
    parser.add_argument("--helper", default=os.getenv("RHCL_HELPER", "root@aws-helper.wzhlab.top"))
    parser.add_argument(
        "--cluster",
        action="append",
        type=parse_cluster,
        default=[],
        help="GROUP:HELPER_USER:BASE_WEIGHT; repeat for every RHCL site",
    )
    parser.add_argument(
        "--strategy",
        action="append",
        choices=["active-groups", "dnspolicy-weight"],
        default=[],
        help="Reconciliation strategy; repeatable",
    )
    parser.add_argument("--active-groups-fqdn", default=DEFAULT_ACTIVE_GROUPS_FQDN)
    parser.add_argument(
        "--policy-crd",
        type=parse_policy_ref,
        help="Load controller config from GlobalTrafficPolicy as HELPER_USER:NAMESPACE:NAME",
    )
    parser.add_argument("--ttl", type=int, default=10)
    parser.add_argument("--geo-source", help="JSON file mapping client CIDRs to preferred RHCL groups")
    parser.add_argument("--client-ip", help="Simulated client IP or ECS prefix address used with --geo-source")
    parser.add_argument("--geo-allow-empty", action="store_true")
    parser.add_argument("--mock-healthy-groups", help="Comma-separated group list for offline decision tests")
    parser.add_argument("--interval", type=int, default=10)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--allow-empty", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        load_policy_from_crd(args)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    if not args.cluster:
        args.cluster = [
            Cluster("demo-01", "sno", 60),
            Cluster("demo-02", "sno2", 30),
            Cluster("demo-03", "sno3", 10),
        ]
    if not args.strategy:
        args.strategy = ["active-groups"]
    if args.ttl <= 0:
        parser.error("--ttl must be > 0")

    if args.once:
        return reconcile(args)

    while True:
        code = reconcile(args)
        if code != 0:
            return code
        time.sleep(args.interval)


if __name__ == "__main__":
    raise SystemExit(main())
