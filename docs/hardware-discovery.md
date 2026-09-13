# Privacy-safe hardware discovery

The inventory stage collects only the technical facts needed to decide which
models and runtimes may fit. It deliberately excludes hostnames, IP addresses,
serial numbers, usernames, credentials, process arguments, and unrelated files.

## Local inventory

Choose an anonymous label and keep the raw report in the ignored private area:

```bash
mkdir -p inventory/private
python3 hardware/inventory.py --label apple-01 \
  > inventory/private/apple-01.json
```

Review the report before using any value in a public benchmark summary.

## Remote inventory over SSH

The script can be streamed to a supported node without copying it permanently:

```bash
ssh your-configured-host 'python3 - --label linux-01' \
  < hardware/inventory.py \
  > inventory/private/linux-01.json
```

Use an existing SSH host alias or address locally; never put it in a committed
example. The private SSH key remains on the operator's machine.

## What the report establishes

The JSON report includes:

- operating-system family, version, kernel, and architecture;
- CPU model and logical core count;
- physical or unified memory;
- free space on the root filesystem;
- graphics or accelerator names visible to the operating system;
- presence of relevant runtime tools; and
- explicit privacy assertions for excluded identifiers.

Tool presence does not prove that acceleration works. Before benchmarking,
confirm the selected runtime can enumerate and use the intended device. On
Linux, a software renderer is not an acceptable substitute for the target GPU.

## Supported systems

Version 0.1 accepts Apple Silicon macOS and Ubuntu Linux. It exits without an
inventory on other operating systems so an agent cannot accidentally present an
untested platform as supported.

The script performs no package installation, networking change, or service
operation. Those remain separate, reviewed stages.
