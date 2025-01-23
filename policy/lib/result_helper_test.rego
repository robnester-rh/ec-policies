package lib_test

import rego.v1

import data.lib

test_result_helper if {
	expected_result := {
		"code": "oh.Hey",
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [
		{"annotations": rule_annotations, "path": ["data", "oh", "deny"]},
		{"annotations": {}, "path": ["ignored", "ignored"]}, # Actually not needed any more
	]

	lib.assert_equal(expected_result, lib.result_helper(chain, ["foo"]))
}

test_result_helper_without_package_annotation if {
	expected_result := {
		"code": "package_name.Hey", # Fixme
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [{"annotations": rule_annotations, "path": ["package_name", "deny"]}]

	lib.assert_equal(expected_result, lib.result_helper(chain, ["foo"]))
}

test_result_helper_with_collections if {
	expected := {
		"code": "some.path.oh.Hey",
		"collections": ["spam"],
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"collections": ["spam"],
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [
		{"annotations": rule_annotations, "path": ["some", "path", "oh", "deny"]},
		{"annotations": {}, "path": ["ignored", "ignored"]}, # Actually not needed any more
	]

	lib.assert_equal(expected, lib.result_helper(chain, ["foo"]))
}

test_result_helper_with_term if {
	expected := {
		"code": "path.oh.Hey",
		"term": "ola",
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [
		{"annotations": rule_annotations, "path": ["data", "path", "oh", "deny"]},
		{"annotations": {}, "path": ["ignored", "also_ignored"]},
	]

	lib.assert_equal(expected, lib.result_helper_with_term(chain, ["foo"], "ola"))
}

test_result_helper_pkg_name if {
	# "Normal" for ec-policies repo
	lib.assert_equal("foo", lib._pkg_name(["data", "foo", "deny"]))
	lib.assert_equal("foo", lib._pkg_name(["data", "foo", "warn"]))

	# Long package paths are retained
	lib.assert_equal("another.foo.bar", lib._pkg_name(["data", "another", "foo", "bar", "deny"]))
	lib.assert_equal("another.foo.bar", lib._pkg_name(["data", "another", "foo", "bar", "warn"]))

	# Unlikely edge case: No deny or warn
	lib.assert_equal("foo", lib._pkg_name(["data", "foo"]))
	lib.assert_equal("foo.bar", lib._pkg_name(["data", "foo", "bar"]))

	# Unlikely edge case: No data
	lib.assert_equal("foo", lib._pkg_name(["foo", "deny"]))
	lib.assert_equal("foo.bar", lib._pkg_name(["foo", "bar", "warn"]))

	# Very unlikely edge case: Just to illustrate how deny/warn/data are stripped once
	lib.assert_equal("foo", lib._pkg_name(["data", "foo", "warn", "deny"]))
	lib.assert_equal("foo.deny", lib._pkg_name(["data", "foo", "deny", "warn"]))
	lib.assert_equal("foo.warn", lib._pkg_name(["data", "foo", "warn", "warn"]))
	lib.assert_equal("data.foo.warn.deny", lib._pkg_name(["data", "data", "foo", "warn", "deny", "warn"]))
}
