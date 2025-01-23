package trusted_task_test

import rego.v1

import data.lib
import data.trusted_task

test_success if {
	att_no_ta := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			newest_bundle_pipeline_task,
			newest_git_pipeline_task,
		]},
	}}}

	lib.assert_empty(trusted_task.warn | trusted_task.deny, expected) with data.trusted_tasks as trusted_tasks_data
		with input.attestations as [att_no_ta, attestation_ta]
}

test_pinned_warning if {
	att := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			trusted_bundle_pipeline_task,
			unpinned_bundle_pipeline_task,
			trusted_git_pipeline_task,
			unpinned_git_pipeline_task,
		]},
	}}}

	expected := {
		{
			"code": "trusted_task.pinned",
			# regal ignore:line-length
			"msg": "Pipeline task \"unpinned-honest-abe-p\" uses an unpinned task reference, git+git.local/repo.git//tasks/honest-abe.yaml@", "term": "honest-abe",
		},
		{
			"code": "trusted_task.pinned",
			# regal ignore:line-length
			"msg": "Pipeline task \"unpinned-trusty-p\" uses an unpinned task reference, oci://registry.local/trusty:1.0@", "term": "trusty",
		},
	}

	lib.assert_equal_results(trusted_task.warn, expected) with input.attestations as [att]
		with data.trusted_tasks as trusted_tasks_data
}

test_outdated_warning if {
	att := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			trusted_bundle_pipeline_task,
			outdated_bundle_pipeline_task,
			trusted_git_pipeline_task,
			outdated_git_pipeline_task,
		]},
	}}}

	expected := {
		{
			"code": "trusted_task.current",
			# regal ignore:line-length
			"msg": "Pipeline task \"outadated-honest-abe-p\" uses an out of date task reference, git+git.local/repo.git//tasks/honest-abe.yaml@37ef630394794f28142224295851a45eea5c63ae. A new version of the task must be used before 2099-01-01T00:00:00Z",
			"term": "honest-abe",
		},
		{
			"code": "trusted_task.current",
			# regal ignore:line-length
			"msg": "Pipeline task \"outdated-trusty-p\" uses an out of date task reference, oci://registry.local/trusty:1.0@sha256:outdated-digest. A new version of the task must be used before 2099-01-01T00:00:00Z",
			"term": "trusty",
		},
	}

	lib.assert_equal_results(trusted_task.warn, expected) with input.attestations as [att]
		with data.trusted_tasks as trusted_tasks_data
}

test_trusted_violation if {
	att := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			trusted_bundle_pipeline_task,
			outdated_bundle_pipeline_task,
			unknown_bundle_pipeline_task,
			expired_bundle_pipeline_task,
			trusted_git_pipeline_task,
			outdated_git_pipeline_task,
			unknown_git_pipeline_task,
			expired_git_pipeline_task,
			inlined_pipeline_task,
		]},
	}}}

	expected := {
		{
			"code": "trusted_task.trusted",
			"msg": "Pipeline task \"crook-p\" uses an untrusted task reference, oci://registry.local/crook:1.0@sha256:digest",
			"term": "crook",
		},
		{
			"code": "trusted_task.trusted",
			# regal ignore:line-length
			"msg": "Pipeline task \"expired-honest-abe-p\" uses an untrusted task reference, git+git.local/repo.git//tasks/honest-abe.yaml@26ef630394794f28142224295851a45eea5c63ae",
			"term": "honest-abe",
		},
		{
			"code": "trusted_task.trusted",
			# regal ignore:line-length
			"msg": "Pipeline task \"expired-trusty-p\" uses an untrusted task reference, oci://registry.local/trusty:1.0@sha256:expired-digest",
			"term": "trusty",
		},
		{
			# regal ignore:line-length
			"code": "trusted_task.trusted", "msg": "Pipeline task \"inlined-p\" uses an untrusted task reference, <UNKNOWN>@<INLINED>",
			"term": "<NAMELESS>",
		},
		{
			"code": "trusted_task.trusted",
			# regal ignore:line-length
			"msg": "Pipeline task \"untrusted-lawless-p\" uses an untrusted task reference, git+git.local/repo.git//tasks/lawless.yaml@37ef630394794f28142224295851a45eea5c63ae",
			"term": "lawless",
		},
	}

	lib.assert_equal_results(trusted_task.deny, expected) with input.attestations as [att]
		with data.trusted_tasks as trusted_tasks_data
}

test_trusted_artifact_tampering if {
	evil_attestation := json.patch(attestation_ta, [{
		"op": "replace",
		"path": "/statement/predicate/buildConfig/tasks/1/ref/bundle",
		"value": "registry.io/evil/bundle@sha256:cde",
	}])

	expected := {
		{
			"code": "trusted_task.trusted",
			# regal ignore:line-length
			"msg": "Code tampering detected, untrusted PipelineTask \"task_b\" (Task \"TaskB\") was included in build chain comprised of: task_a, task_b, task_c",
			"term": "TaskB",
		},
		{
			"code": "trusted_task.trusted",
			# regal ignore:line-length
			"msg": `Code tampering detected, untrusted PipelineTask "task_b" (Task "TaskB") was included in build chain comprised of: task_b, task_c, task_test_a`,
			"term": "TaskB",
		},
	}

	lib.assert_equal_results(trusted_task.deny, expected) with data.trusted_tasks as trusted_tasks_data
		with input.attestations as [evil_attestation]
}

test_trusted_artifact_test_tasks if {
	lib.assert_empty(trusted_task.deny) with data.trusted_tasks as trusted_tasks_data
		with input.attestations as [attestation_ta]
}

test_tampered_trusted_artifact_inputs if {
	evil_attestation := json.patch(attestation_ta, [{
		"op": "add",
		"path": "/statement/predicate/buildConfig/tasks/1/invocation/parameters/F_ARTIFACT",
		"value": "oci:registry.io/repository/image@sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
	}])

	lib.assert_equal_results(trusted_task.deny, {{
		"code": "trusted_task.valid_trusted_artifact_inputs",
		# regal ignore:line-length
		"msg": `Code tampering detected, input "oci:registry.io/repository/image@sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" for task "task_b" was not produced by the pipeline as attested.`,
		"term": "oci:registry.io/repository/image@sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
	}}) with data.trusted_tasks as trusted_tasks_data
		with input.attestations as [evil_attestation]
}

test_artifact_chain if {
	expected := {
		"task_a": {"task_b", "task_c"},
		"task_b": {"task_c"},
		"task_c": set(),
		"task_image_index": set(),
		"task_test_a": {"task_b"},
	}

	lib.assert_equal(trusted_task._artifact_chain[attestation_ta], expected) with input.attestations as [attestation_ta]
}

test_trusted_artifact_inputs_from_parameters if {
	task := {"invocation": {"parameters": {
		"param1": "value1",
		"SOME_ARTIFACT": "value2",
		"SOURCE_ARTIFACT": artifact_a,
		# regal ignore:line-length
		"UNEXPECTED_ARTIFACT": "oci:registry.io/repository/image@sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	}}}

	lib.assert_equal(trusted_task._trusted_artifact_inputs(task), {artifact_a})
}

test_trusted_artifact_outputs_from_results if {
	task := {"results": [
		{
			"name": "result1",
			"value": "value1",
			"type": "string",
		},
		{
			"name": "SOME_ARTIFACT",
			"value": "value2",
			"type": "string",
		},
		{
			"name": "SOURCE_ARTIFACT",
			"value": artifact_a,
			"type": "string",
		},
		{
			"name": "UNEXPECTED1_ARTIFACT",
			"value": "oci:registry.io/repository/image@sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
			"type": "string",
		},
		{
			"name": "UNEXPECTED2_ARTIFACT",
			"value": artifact_a,
			"type": "array",
		},
	]}

	lib.assert_equal(
		trusted_task._trusted_artifact_outputs(task),
		{artifact_a},
	)
}

test_trusted_parameters if {
	evil_attestation := json.patch(attestation_ta, [{
		"op": "add",
		"path": "/statement/predicate/buildConfig/tasks/3/invocation/parameters/image",
		"value": "registry.io/repository/image@sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
	}])

	lib.assert_equal_results(trusted_task.deny, {{
		"code": "trusted_task.trusted_parameters",
		# regal ignore:line-length
		"msg": `The "image" parameter of the "task_image_index" PipelineTask includes an untrusted digest: sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff`,
	}}) with data.trusted_tasks as trusted_tasks_data
		with input.attestations as [evil_attestation]
}

test_data_missing if {
	expected := {{"code": "trusted_task.data", "msg": "Missing required trusted_tasks data"}}
	lib.assert_equal_results(trusted_task.deny, expected) with data.trusted_tasks as []
}

test_data_errors if {
	# Data validation happens in tkn.data_errors. Only need to test that errors are propagated.
	bad_data := {"spam": [{"spam": "spam"}]}
	expected := {
		{
			"code": "trusted_task.data_format",
			"msg": "trusted_tasks data has unexpected format: spam.0: Additional property spam is not allowed",
			"severity": "warning",
		},
		{
			"code": "trusted_task.data_format",
			"msg": "trusted_tasks data has unexpected format: spam.0: effective_on is required",
			"severity": "failure",
		},
		{
			"code": "trusted_task.data_format",
			"msg": "trusted_tasks data has unexpected format: spam.0: ref is required",
			"severity": "failure",
		},
	}
	lib.assert_equal_results(trusted_task.deny, expected) with data.trusted_tasks as bad_data
}

#########################################
# Pipeline Tasks using bundles resolver #
#########################################

trusted_bundle_pipeline_task := {
	"name": "trusty-p",
	"ref": {"resolver": "bundles", "params": [
		{"name": "bundle", "value": "registry.local/trusty:1.0@sha256:digest"},
		{"name": "name", "value": "trusty"},
		{"name": "kind", "value": "task"},
	]},
}

newest_bundle_pipeline_task := trusted_bundle_pipeline_task

outdated_bundle_pipeline_task := {
	"name": "outdated-trusty-p",
	"ref": {"resolver": "bundles", "params": [
		{"name": "bundle", "value": "registry.local/trusty:1.0@sha256:outdated-digest"},
		{"name": "name", "value": "trusty"},
		{"name": "kind", "value": "task"},
	]},
}

expired_bundle_pipeline_task := {
	"name": "expired-trusty-p",
	"ref": {"resolver": "bundles", "params": [
		{"name": "bundle", "value": "registry.local/trusty:1.0@sha256:expired-digest"},
		{"name": "name", "value": "trusty"},
		{"name": "kind", "value": "task"},
	]},
}

unpinned_bundle_pipeline_task := {
	"name": "unpinned-trusty-p",
	"ref": {"resolver": "bundles", "params": [
		{"name": "bundle", "value": "registry.local/trusty:1.0"},
		{"name": "name", "value": "trusty"},
		{"name": "kind", "value": "task"},
	]},
}

unknown_bundle_pipeline_task := {
	"name": "crook-p",
	"ref": {"resolver": "bundles", "params": [
		{"name": "bundle", "value": "registry.local/crook:1.0@sha256:digest"},
		{"name": "name", "value": "crook"},
		{"name": "kind", "value": "task"},
	]},
}

#####################################
# Pipeline Tasks using git resolver #
#####################################

trusted_git_pipeline_task := {
	"name": "honest-abe-p",
	"ref": {"resolver": "git", "params": [
		{"name": "revision", "value": "48df630394794f28142224295851a45eea5c63ae"},
		{"name": "pathInRepo", "value": "tasks/honest-abe.yaml"},
		{"name": "url", "value": "git.local/repo.git"},
	]},
	"invocation": {"environment": {"labels": {"tekton.dev/task": "honest-abe"}}},
}

newest_git_pipeline_task := trusted_git_pipeline_task

outdated_git_pipeline_task := {
	"name": "outadated-honest-abe-p",
	"ref": {"resolver": "git", "params": [
		{"name": "revision", "value": "37ef630394794f28142224295851a45eea5c63ae"},
		{"name": "pathInRepo", "value": "tasks/honest-abe.yaml"},
		{"name": "url", "value": "git.local/repo.git"},
	]},
	"invocation": {"environment": {"labels": {"tekton.dev/task": "honest-abe"}}},
}

expired_git_pipeline_task := {
	"name": "expired-honest-abe-p",
	"ref": {"resolver": "git", "params": [
		{"name": "revision", "value": "26ef630394794f28142224295851a45eea5c63ae"},
		{"name": "pathInRepo", "value": "tasks/honest-abe.yaml"},
		{"name": "url", "value": "git.local/repo.git"},
	]},
	"invocation": {"environment": {"labels": {"tekton.dev/task": "honest-abe"}}},
}

unpinned_git_pipeline_task := {
	"name": "unpinned-honest-abe-p",
	"ref": {"resolver": "git", "params": [
		{"name": "revision", "value": "main"},
		{"name": "pathInRepo", "value": "tasks/honest-abe.yaml"},
		{"name": "url", "value": "git.local/repo.git"},
	]},
	"invocation": {"environment": {"labels": {"tekton.dev/task": "honest-abe"}}},
}

unknown_git_pipeline_task := {
	"name": "untrusted-lawless-p",
	"ref": {"resolver": "git", "params": [
		{"name": "revision", "value": "37ef630394794f28142224295851a45eea5c63ae"},
		{"name": "pathInRepo", "value": "tasks/lawless.yaml"},
		{"name": "url", "value": "git.local/repo.git"},
	]},
	"invocation": {"environment": {"labels": {"tekton.dev/task": "lawless"}}},
}

##########################
# Inlined Pipeline Tasks #
##########################

inlined_pipeline_task := {
	"name": "inlined-p",
	"ref": {},
}

###########################
# Trusted Artifacts data #
###########################

artifact_a := "oci:registry.io/repository/image@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

artifact_b := "oci:registry.io/repository/image@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

artifact_c := "oci:registry.io/repository/image@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

artifact_d := "oci:registry.io/repository/image@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"

image_a_digest := "sha256:49a6fd43239ae41643426daefc5239857a1cc1a6f2c1595f88965d7de88efcb9"

image_index_digest := "sha256:6e69e396950defe6ff7981636e30498f99128310a4ee37a87c48729888cb77b3"

trusted_bundle := "registry.local/trusty:1.0@sha256:digest"

task_image_index := {
	"metadata": {"labels": {"tekton.dev/pipelineTask": "task_image_index"}},
	"invocation": {"parameters": {"image": sprintf("registry.io/repository/image@%s", [image_a_digest])}},
	"results": [
		{
			"name": "IMAGE_URL",
			"value": "registry.io/repository/image",
			"type": "string",
		},
		{
			"name": "IMAGE_DIGEST",
			"value": image_index_digest,
			"type": "string",
		},
	],
	"ref": {"name": "TaskA", "kind": "Task", "bundle": trusted_bundle},
}

task_a := {
	"metadata": {"labels": {"tekton.dev/pipelineTask": "task_a"}},
	"invocation": {"parameters": {"B_ARTIFACT": artifact_b, "D_ARTIFACT": artifact_d}},
	"results": [
		{
			"name": "IMAGE_URL",
			"value": "registry.io/repository/image",
			"type": "string",
		},
		{
			"name": "IMAGE_DIGEST",
			"value": image_a_digest,
			"type": "string",
		},
	],
	"ref": {"name": "TaskA", "kind": "Task", "bundle": trusted_bundle},
}

task_b := {
	"metadata": {"labels": {"tekton.dev/pipelineTask": "task_b"}},
	"invocation": {"parameters": {"C_ARTIFACT": artifact_c}},
	"results": [{
		"name": "B_ARTIFACT",
		"value": artifact_b,
		"type": "string",
	}],
	"ref": {"name": "TaskB", "kind": "Task", "bundle": trusted_bundle},
}

task_c := {
	"metadata": {"labels": {"tekton.dev/pipelineTask": "task_c"}},
	"results": [
		{
			"name": "C_ARTIFACT",
			"value": artifact_c,
			"type": "string",
		},
		{
			"name": "D_ARTIFACT",
			"value": artifact_d,
			"type": "string",
		},
	],
	"ref": {"name": "TaskC", "kind": "Task", "bundle": trusted_bundle},
}

task_test_a := {
	"metadata": {"labels": {"tekton.dev/pipelineTask": "task_test_a"}},
	"invocation": {"parameters": {"B_ARTIFACT": artifact_b}},
	"results": [{
		"name": "TEST_OUTPUT",
		"value": "{\"FAILED\": \"1\"}",
		"type": "string",
	}],
	"ref": {"name": "TaskTestA", "kind": "Task", "bundle": trusted_bundle},
}

attestation_ta := {"statement": {"predicate": {
	"buildType": lib.tekton_pipeline_run,
	"buildConfig": {"tasks": [task_a, task_b, task_c, task_image_index, task_test_a]},
}}}

######################
# Trusted Tasks data #
######################

trusted_tasks_data := {
	"oci://registry.local/trusty:1.0": [
		{
			"ref": "sha256:digest",
			"effective_on": "2099-01-01T00:00:00Z",
		},
		{
			"ref": "sha256:outdated-digest",
			"effective_on": "2024-01-01T00:00:00Z",
			"expires_on": "2099-01-01T00:00:00Z",
		},
		{
			"ref": "sha256:expired-digest",
			"effective_on": "2023-01-01T00:00:00Z",
			"expires_on": "2024-01-01T00:00:00Z",
		},
	],
	"git+git.local/repo.git//tasks/honest-abe.yaml": [
		{
			"ref": "48df630394794f28142224295851a45eea5c63ae",
			"effective_on": "2099-01-01T00:00:00Z",
		},
		{
			"ref": "37ef630394794f28142224295851a45eea5c63ae",
			"effective_on": "2024-01-01T00:00:00Z",
			"expires_on": "2099-01-01T00:00:00Z",
		},
		{
			"ref": "26ef630394794f28142224295851a45eea5c63ae",
			"effective_on": "2023-01-01T00:00:00Z",
			"expires_on": "2024-01-01T00:00:00Z",
		},
	],
}
