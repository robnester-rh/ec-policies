package rpm_ostree_task_test

import rego.v1

import data.lib
import data.rpm_ostree_task

test_success if {
	slsa_v02_attestation := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [{
			"name": "rpm-ostree-p",
			"ref": {"kind": "Task", "name": "rpm-ostree"},
			"invocation": {"parameters": {"BUILDER_IMAGE": "registry.local/builder:v0.2@sha256:abc"}},
		}]},
	}}}

	slsa_v1_attestation := {"statement": {
		"predicateType": "https://slsa.dev/provenance/v1",
		"predicate": {"buildDefinition": {
			"buildType": "https://tekton.dev/chains/v2/slsa-tekton",
			"externalParameters": {"runSpec": {"pipelineSpec": {}}},
			"resolvedDependencies": [{
				"name": "pipelineTask",
				"content": base64.encode(json.marshal({"spec": {
					"taskRef": {
						"name": "rpm-ostree",
						"kind": "Task",
					},
					"params": [{
						"name": "BUILDER_IMAGE",
						"value": "registry.local/builder:v1.0@sha256:bcd",
					}],
				}})),
			}],
		}},
	}}

	attestations := [slsa_v02_attestation, slsa_v1_attestation]

	lib.assert_empty(rpm_ostree_task.deny) with input.attestations as attestations
		with data.rule_data.allowed_rpm_ostree_builder_image_prefixes as ["registry.local/builder"]
}

test_builder_image_param_failures if {
	slsa_v02_attestation := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			{
				"name": "rpm-ostree-1",
				"ref": {"kind": "Task", "name": "rpm-ostree"},
				"invocation": {"parameters": {"BUILDER_IMAGE": "registry.local/spam:v0.2"}},
			},
			{
				"name": "rpm-ostree-2",
				"ref": {"kind": "Task", "name": "rpm-ostree"},
				"invocation": {"parameters": {"BUILDER_IMAGE": "registry.local/deprecated:v0.2@sha256:abc"}},
			},
		]},
	}}}

	slsa_v1_attestation := {"statement": {
		"predicateType": "https://slsa.dev/provenance/v1",
		"predicate": {"buildDefinition": {
			"buildType": "https://tekton.dev/chains/v2/slsa-tekton",
			"externalParameters": {"runSpec": {"pipelineSpec": {}}},
			"resolvedDependencies": [
				{
					"name": "pipelineTask",
					"content": base64.encode(json.marshal({"spec": {
						"taskRef": {
							"name": "rpm-ostree",
							"kind": "Task",
						},
						"params": [{
							"name": "BUILDER_IMAGE",
							"value": "registry.local/spam:v1.0",
						}],
					}})),
				},
				{
					"name": "pipelineTask",
					"content": base64.encode(json.marshal({"spec": {
						"taskRef": {
							"name": "rpm-ostree",
							"kind": "Task",
						},
						"params": [{
							"name": "BUILDER_IMAGE",
							"value": "registry.local/deprecated:v1.0@sha256:bcd",
						}],
					}})),
				},
			],
		}},
	}}

	attestations := [slsa_v02_attestation, slsa_v1_attestation]

	expected := {
		# Prefix with an expiration date
		{
			"code": "rpm_ostree_task.builder_image_param",
			# regal ignore:line-length
			"msg": "BUILDER_IMAGE \"registry.local/deprecated:v0.2@sha256:abc\" starts with \"registry.local/deprecated\" prefix that expires on 2099-01-01T00:00:00Z",
			"effective_on": "2099-01-01T00:00:00Z",
		},
		{
			"code": "rpm_ostree_task.builder_image_param",
			# regal ignore:line-length
			"msg": "BUILDER_IMAGE \"registry.local/deprecated:v1.0@sha256:bcd\" starts with \"registry.local/deprecated\" prefix that expires on 2099-01-01T00:00:00Z",
			"effective_on": "2099-01-01T00:00:00Z",
		},
		# Prefix not allowed
		{
			"code": "rpm_ostree_task.builder_image_param",
			# regal ignore:line-length
			"msg": "BUILDER_IMAGE \"registry.local/spam:v0.2\" does not start with a pre-approved prefix: registry.local/builder, registry.local/deprecated",
			"effective_on": "2024-03-20T00:00:00Z",
		},
		{
			"code": "rpm_ostree_task.builder_image_param",
			# regal ignore:line-length
			"msg": "BUILDER_IMAGE \"registry.local/spam:v1.0\" does not start with a pre-approved prefix: registry.local/builder, registry.local/deprecated",
			"effective_on": "2024-03-20T00:00:00Z",
		},
		# Not pinned
		{
			"code": "rpm_ostree_task.builder_image_param",
			"msg": "BUILDER_IMAGE \"registry.local/spam:v0.2\" is not pinned to a digest",
			"effective_on": "2024-03-20T00:00:00Z",
		},
		{
			"code": "rpm_ostree_task.builder_image_param",
			"msg": "BUILDER_IMAGE \"registry.local/spam:v1.0\" is not pinned to a digest",
			"effective_on": "2024-03-20T00:00:00Z",
		},
	}

	allowed_prefixes := [
		"registry.local/builder",
		{"value": "registry.local/deprecated", "expires_on": "2099-01-01T00:00:00Z"},
	]

	lib.assert_equal_results_no_collections(expected, rpm_ostree_task.deny) with input.attestations as attestations
		with data.rule_data.allowed_rpm_ostree_builder_image_prefixes as allowed_prefixes
}

test_rule_data_failures if {
	rd := {"allowed_rpm_ostree_builder_image_prefixes": [
		# Unexpected type
		["spam"],
		# Missing required object attributes
		{"expires_on": "2030-01-01T00:00:00Z"},
		# Additional attributes not allowed
		{"spam": "maps", "value": "registry.local/repo", "expires_on": "2030-01-01T00:00:00Z"},
		# Incorrect type attributes
		{"value": 0, "expires_on": 1},
	]}

	expected := {
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 0: Invalid type. Expected: object, given: array",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 0: Must validate at least one schema (anyOf)",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 1: value is required",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 1: Must validate at least one schema (anyOf)",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 2: Additional property spam is not allowed",
			"severity": "warning",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 2: Must validate at least one schema (anyOf)",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 3.expires_on: Invalid type. Expected: string, given: integer",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 3.value: Invalid type. Expected: string, given: integer",
			"severity": "failure",
		},
		{
			"code": "rpm_ostree_task.rule_data",
			# regal ignore:line-length
			"msg": "Rule data allowed_rpm_ostree_builder_image_prefixes has unexpected format: 3: Must validate at least one schema (anyOf)",
			"severity": "failure",
		},
	}

	lib.assert_equal_results(expected, rpm_ostree_task.deny) with data.rule_data as rd
}
