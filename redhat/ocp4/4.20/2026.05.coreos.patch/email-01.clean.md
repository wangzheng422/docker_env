# CVE-2026-31431 ("Copy Fail"): CoreOS Patching vs RHEL — Guidance for OpenShift Customers

## Short Answer

CoreOS (RHCOS) follows the **same CVE policy** as RHEL — the same vulnerabilities are tracked, and patches are released — but the **delivery and application method is different** because RHCOS is an immutable OS tightly coupled with OpenShift.

**A z-stream upgrade is sufficient.** There is **no** need to upgrade to a new OCP minor version. Red Hat has already released fixes for all supported OCP versions (4.12 through 4.21) as z-stream updates.

## Key Differences: RHEL vs CoreOS Patching

| | RHEL | CoreOS (RHCOS) |
|---|---|---|
| **Kernel patch** | `dnf update kernel` + reboot | OCP z-stream upgrade (`oc adm upgrade`) — MCO handles rolling reboot automatically |
| **kpatch (live patching)** | Supported (no reboot) | **Not available** on RHCOS |
| **Boot parameter change** | `grubby` + reboot | MachineConfig CR — MCO handles rolling reboot |
| **Rebootless mitigation** | kpatch | eBPF DaemonSet (x86_64 only, CVE-specific) |

## Remediation Options for CVE-2026-31431 on OCP

**Option 1 — z-stream upgrade (Recommended)**

Upgrade to the fixed z-stream version for the current OCP release. Examples:

- 4.16 → **4.16.61** ([RHSA-2026:13729](https://access.redhat.com/errata/RHSA-2026:13729))
- 4.18 → **4.18.40** ([RHSA-2026:13727](https://access.redhat.com/errata/RHSA-2026:13727))
- 4.20 → **4.20.21** ([RHSA-2026:13862](https://access.redhat.com/errata/RHSA-2026:13862))

Full list of fixed versions: [KCS 7141979](https://access.redhat.com/solutions/7141979)

The upgrade process is standard and nodes reboot in a rolling fashion managed by the Machine Config Operator — not all at once.

**Option 2 — eBPF DaemonSet (No reboot, immediate)**

If the cluster cannot be upgraded right away, Red Hat Engineering provides a rebootless mitigation via a BPF LSM DaemonSet that blocks access to the vulnerable kernel function. Details: [block-copyfail on GitHub](https://github.com/openshift/block-copyfail). This works on x86_64 only and should be removed after upgrading.

**Option 3 — MachineConfig kernel argument (Reboot required)**

Add `initcall_blacklist=algif_aead_init` via MachineConfig. This triggers a rolling reboot but is more reliable than the eBPF approach. Details in [KCS 7141979](https://access.redhat.com/solutions/7141979).

## References

- RHEL mitigation: [KCS 7141931](https://access.redhat.com/solutions/7141931)
- OCP mitigation (detailed steps): [KCS 7141979](https://access.redhat.com/solutions/7141979)
- Security Bulletin: [RHSB-2026-02](https://access.redhat.com/security/vulnerabilities/RHSB-2026-02)
