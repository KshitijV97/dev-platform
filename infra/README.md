# Oracle infrastructure

This directory provisions the Phase 1 primary node: one Always Free `VM.Standard.A1.Flex` in a Canadian region, with a public subnet and a cloud-init bootstrap.

## Prerequisites

- An OCI account with the Always Free tier.
- An API key and a `~/.oci/config` profile (`oci setup config`).
- The tenancy OCID and a compartment OCID.
- An SSH key pair. Only the public key goes into `terraform.tfvars`.
- Optional: a single-use, pre-authorized Tailscale auth key.

## Usage

```bash
cd infra/oracle
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

Then:

```bash
terraform output public_ip
ssh deploy@$(terraform output -raw public_ip)
```

Cloud-init logs are at `/var/log/cloud-init-output.log`.

## Capacity

A1 capacity is the usual failure point. If `apply` returns `Out of host capacity`:

1. Retry every few hours.
2. Try the other Canadian region in a new tenancy if this is a fresh account. The home region is permanent.
3. Consider upgrading the account to Pay As You Go; Always Free resources remain free, but a card is on file.

Do not create multiple accounts to work around capacity. It violates the one-account-per-person rule.

## State and secrets

- Local state is acceptable for one operator. Move to an OCI Object Storage backend before a second operator or a client handover.
- `terraform.tfvars` and `*.tfstate` are gitignored.
- `tailscale_auth_key` is stored in state and in instance metadata. Use a single-use key and revoke it after the node joins.
- The instance's `metadata` is ignored after creation so cloud-init does not rerun on every apply.

## Teardown

```bash
terraform destroy
```

This deletes the instance and boot volume. Take a backup or a boot volume backup first. The VCN and subnet are also removed.
