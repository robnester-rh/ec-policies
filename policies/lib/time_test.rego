# METADATA
# custom:
#   effective_on: 2001-02-03T00:00:00Z
#   scope: package
package lib.time

future_timestamp := time.add_date(time.now_ns(), 0, 0, 1)

# METADATA
# custom:
#   effective_on: 2004-05-06T00:00:00Z
test_when_rule_precedence {
	when(rego.metadata.chain()) == "2004-05-06T00:00:00Z"
}

test_when_package_precedence {
	when(rego.metadata.chain()) == "2001-02-03T00:00:00Z"
}
