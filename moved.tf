# Intentionally empty — do NOT add `moved` blocks for the RDS subnet group /
# security group / alarms refactor.
#
# The live state contains DUPLICATE entries: the same physical AWS resource is
# recorded under both its old module address and its new one. A `moved` block
# requires an EMPTY destination, so moving onto the already-occupied new address
# fails the plan instead of cleaning it.
#
# The correct reconciliation is `terraform state rm` of the stale duplicate
# addresses, run once in a controlled session.
#
# See ./STATE-RECONCILE.md for the full finding and the exact procedure.
